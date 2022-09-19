clc;
clear;
close all;

%reading conf.json file

finput = 'conf.json'; 
finput_id = fopen(finput); 
raw = fread(finput_id,inf); 
str = char(raw'); 
fclose(finput_id); 
val = jsondecode(str);
[a b] = size (val);

delete('output.json');

%fid = fopen('output.json','w');
% fields = ['protocol_name','outputs':{'total_tx_time','overhead','efficiency'}];
% jsonstruct = struct('protocol_name','total_tx_time','overhead','efficiency');
% jsonstruct = rmfield(jsonstruct,fields)

jsonstruct.protocol_name = '';
jsonstruct.outputs = {};
jsonstruct.outputs.total_tx_time = 0;
jsonstruct.outputs.overhead = 0;
jsonstruct.outputs.efficiency = 0;
jsonstruct = struct(jsonstruct);

for i = 1:a
    
    if val(i).protocol_name == "USB"
        sync_pattern = val(i).parameters.sync_pattern;
        pid = val(i).parameters.pid;
        dest_address = val(i).parameters.dest_address;
        payload = val(i).parameters.payload;
        bit_duration_usb = val(i).parameters.bit_duration;
        
        
        length_of_add=length(dest_address);
        dest_address_reshape=reshape(dest_address,length_of_add,1);
        dest_address_bin=dest_address_reshape-'0';
        dest_address_final=flip(dest_address_bin);
        length_of_sync=length(sync_pattern);
        sync_pattern_reshape=reshape(sync_pattern,length_of_sync,1);
        sync_pattern_final=sync_pattern_reshape-'0';        

        length_of_add=length(dest_address);
        dest_address_reshape=reshape(dest_address,length_of_add,1);
        dest_address_bin=dest_address_reshape-'0';
        dest_address_final=flip(dest_address_bin);
        length_of_sync=length(sync_pattern);
        sync_pattern_reshape=reshape(sync_pattern,length_of_sync,1);
        sync_pattern_final=sync_pattern_reshape-'0';
        overhead_percentage_usb_arr=[];
        total_tx_time_usb_arr=[];
        
        %txt data to binary
        fid =fopen('data.txt');
        x=fread(fid,'* char');

        for o=1:100
    
            if o>1       
                x=[x ;x(1:10,:)];    
            end
            
            lengthofdata=length(x);
            reminder=rem(lengthofdata,payload);
            data1=x(1:(lengthofdata-reminder),:);
            binary= dec2bin(data1,8);
            binary_t = transpose(binary);
            binary_f=flip(binary_t);
            data_bin=binary_f-'0';
            data_bin_reshap=reshape(data_bin,payload*8,[]);
            
            %rem data
            data_rem=x((lengthofdata-reminder+1):lengthofdata,:);
            binary_rem= dec2bin(data_rem,8);
            binary_t_rem = transpose(binary_rem);
            binary_f_rem=flip(binary_t_rem);
            data_bin_rem=binary_f_rem-'0';
            data_bin_rem_reshap=reshape(data_bin_rem,[],1);
            num_of_packets=floor(lengthofdata/payload);

            if rem(lengthofdata,payload)>0
                num_of_packets=floor(lengthofdata/payload)+1;
            end

            %pid

            for k=1:num_of_packets
                PID_matrix (k)= rem(k,16) ;
            end
            
            PID_matrix_t=transpose(PID_matrix);
            Binary_PID_matrix= dec2bin(PID_matrix_t,pid);
            Binary_PID_matrix_t = transpose(Binary_PID_matrix);
            Binary_PID_matrix_f=flip(Binary_PID_matrix_t);
            Matrix = Binary_PID_matrix_f()-'0';
            Matrix2= Matrix(1:4,:);
            Matrix2_not=~Matrix2;
            Final_PID_Matrix=[Matrix2;Matrix2_not];  %concatenate
           
            %repeating sync
            sync_pattern_arr=[];

            for i=1:num_of_packets
                sync_pattern_arr=[sync_pattern_arr sync_pattern_final];   
            end
            
            %repeating address
            dest_address_arr=[];

            for i=1:num_of_packets
                dest_address_arr=[dest_address_arr dest_address_final];   
            end
            
            %all packets

            if rem(lengthofdata,payload)>0
                final_data_befor_nrzi=[sync_pattern_arr(:,1:num_of_packets-1);Final_PID_Matrix(:,1:num_of_packets-1);dest_address_arr(:,1:num_of_packets-1);data_bin_reshap];    
                final_rem_data_befor_nrzi=[sync_pattern_arr(:,num_of_packets);Final_PID_Matrix(:,num_of_packets);dest_address_arr(:,num_of_packets);data_bin_rem_reshap]; 
            else
                final_data_befor_nrzi=[sync_pattern_arr;Final_PID_Matrix;dest_address_arr;data_bin_reshap];
            end
            
            %counting stuffed bits for data without rem
            ones_count = 0;
            stuffing_bit_count = 0;
            total_stuffing_bit=0;
            [c, d] = size(final_data_befor_nrzi);

            for k = 1:d  %each row have packet
    
                for i= 1:c
                    y = final_data_befor_nrzi(i,k);
    
                    if y == 0
                        ones_count = 0;
                    else
                        ones_count = ones_count +1;
        
                        if ones_count == 6
         
                            stuffing_bit_count = stuffing_bit_count +1;
                            ones_count = 0;
       
                        end
                        
                    end
                    
                    
                end
                
                stuffing_bit_matrix(1,k)=  stuffing_bit_count;
                stuffing_bit_count=0;
                ones_count = 0;

            end
            
            total_stuffing_bit=0;

            for  z=1:length(stuffing_bit_matrix)
                total_stuffing_bit=total_stuffing_bit+ stuffing_bit_matrix(z);
            end
            
            if rem(lengthofdata,payload)>0

                len_of_rem_data=length(final_rem_data_befor_nrzi);
                stuffing_bit_count_rem=0;
  
                for v=1:final_rem_data_befor_nrzi
                    y = final_rem_data_befor_nrzi(v);
    
                    if y == 0
        
                        ones_count = 0;
    
                    else
                        ones_count = ones_count +1;
       
                        if ones_count == 6
        
                            stuffing_bit_count_rem = stuffing_bit_count_rem +1;
                            ones_count = 0;
        
                        end
                        
                    end
                    
                    ones_count = 0;

                end
                
                final_rem_data_befor_nrzi_one_row = reshape(final_rem_data_befor_nrzi,1,[]);
                data_rem_withbitstuffing = regexprep(char(final_rem_data_befor_nrzi_one_row + '0'),'111111','1111110')-'0';
            end
            
            %bit stuffing
            final_data_befor_nrzi_one_row = reshape(final_data_befor_nrzi,1,[]);
            data_length = length(final_data_befor_nrzi_one_row);
            data_withbitstuffing = regexprep(char(final_data_befor_nrzi_one_row + '0'),'111111','1111110')-'0';
        
            %nrzi
            final_data_after_nrzi_one_row=[1];

            for counter=1:length(data_withbitstuffing)
    
                if (data_withbitstuffing(counter)==1)
        
                    final_data_after_nrzi_one_row (counter+1)=final_data_after_nrzi_one_row (counter);
    
                else
                    
                    final_data_after_nrzi_one_row (counter+1)= ~ final_data_after_nrzi_one_row (counter);

                end
                
            end
            
            final_data_after_nrzi_one_row=final_data_after_nrzi_one_row(:,2:end);

            if rem(lengthofdata,payload)>0
    
                if final_data_after_nrzi_one_row(end)==1
    
                    final_data_rem_after_nrzi_one_row=[1];
    
                else
                    
                    final_data_rem_after_nrzi_one_row=[0];
    
                end
                
                for counter=1:length(data_rem_withbitstuffing)
    
                    if (data_rem_withbitstuffing(counter)==1)
        
                        final_data_rem_after_nrzi_one_row (counter+1)=final_data_rem_after_nrzi_one_row (counter);
    
                    else
                        
                        final_data_rem_after_nrzi_one_row (counter+1)= ~ final_data_rem_after_nrzi_one_row (counter);
    
                    end
                    
                end
                
                data_rem_eop=[];
                data_rem_eop=[final_data_rem_after_nrzi_one_row(:,2:end) 0 0];    
    
            end
                       
            [g, h]=size(stuffing_bit_matrix);
            endof_curr_packet = 0;
            endof_curr_packet_arr = zeros;
            curr_total_sb = 0;
            data_EOP = [];

            for j = 1:h
            
                curr_total_sb = curr_total_sb + stuffing_bit_matrix(j);
                endof_curr_packet = j*c + curr_total_sb;
                endof_curr_packet_arr(j + 1) = endof_curr_packet;   
       
            end
            
            startof_curr_packet_arr = endof_curr_packet_arr(1:end-1) +1;
            endof_curr_packet_arr = endof_curr_packet_arr(2:end);

            for j = 1:h
            
                data_EOP =[data_EOP final_data_after_nrzi_one_row(:,startof_curr_packet_arr(j):endof_curr_packet_arr(j)) 0 0 ];        
        
            end
            
            test_data_eop=reshape(data_EOP,[],1);
            test_noend=reshape(final_data_after_nrzi_one_row,[],1);
        
            if rem(lengthofdata,payload)>0
        
                final_transmitted_data=[data_EOP data_rem_eop];
        
            else
                
                final_transmitted_data=data_EOP;
        
            end
                       
            %drawing first 2 packets

            if o==1

                two_packets_arr=[];

                for i=1:endof_curr_packet_arr(2)+4
    
                    two_packets_arr(i)=final_transmitted_data(i);

                end
                
                Ts_usb=0:bit_duration_usb:bit_duration_usb*(endof_curr_packet_arr(2)+3);
                figure
                hold on 
                two_packets_arr_plus = two_packets_arr;
                two_packets_arr_minus = ~two_packets_arr;
                stairs(Ts_usb,two_packets_arr_plus);
                stairs(Ts_usb,two_packets_arr_minus+2);
                xlabel('Time');
                ylabel('Transsmitted Data Plus and Minus');
                ylim([-1 4]);
                
                Ts_usb=0:bit_duration_usb:bit_duration_usb*(29);
                figure
                hold on 
                two_packets_arr_plus = two_packets_arr(:,1:30);
                two_packets_arr_minus = ~two_packets_arr(:,1:30);
                stairs(Ts_usb,two_packets_arr_plus);
                stairs(Ts_usb,two_packets_arr_minus+2);
                xlabel('Time');
                ylabel('Transsmitted Data Plus and Minus');
                ylim([-1 4]);
                
                
            end
            
            %if bit_duration_usb==bit_duration_uart
            total_data_length=length(final_transmitted_data);
            total_tx_time_usb=bit_duration_usb*length(final_transmitted_data);
            total_tx_time_usb_arr=[total_tx_time_usb_arr total_tx_time_usb];
            syncpatternlen=length(sync_pattern_final)*num_of_packets;
            pidlen=pid*num_of_packets;
            addresslen=length(dest_address)*num_of_packets;
            [r, z]=size(data_bin_reshap);
            datalen=r*z+length(data_bin_rem_reshap);
            eoplen=2*num_of_packets;

            if rem(lengthofdata,payload)>0

                overheadlength_usb=syncpatternlen+pidlen+addresslen+eoplen+total_stuffing_bit+stuffing_bit_count_rem;

                %tst=syncpatternlen+pidlen+addresslen+eoplen+total_stuffing_bit+stuffing_bit_count_rem+datalen
            else
                
                overheadlength_usb=syncpatternlen+pidlen+addresslen+eoplen+total_stuffing_bit;
   
            end
            
            totaltxdatalen=length(final_transmitted_data);
            overhead_percentage_usb=(overheadlength_usb/totaltxdatalen)*100;
            overhead_percentage_usb_arr=[overhead_percentage_usb_arr overhead_percentage_usb];
            effiecncy_percentage_usb=100-overhead_percentage_usb_arr(:,1);

        end
        
        figure
        plot(overhead_percentage_usb_arr);
        xlabel('File Size');
        ylabel('overhead');
        
        figure
        plot(total_tx_time_usb_arr);
        xlabel('File Size');
        ylabel('Total Transmission Time');
        
        fid = fopen('output.json','w');
        
        jsonstruct(1).protocol_name = "USB";
        jsonstruct(1).outputs.total_tx_time = total_tx_time_usb_arr(:,1);
        jsonstruct(1).outputs.overhead = overhead_percentage_usb_arr(:,1);
        jsonstruct(1).outputs.efficiency = effiecncy_percentage_usb;
     
        jsonData = jsonencode(jsonstruct);

        Data = strrep(jsonData, ',', ',\n');

        Data = strrep(Data, '{', ',{\n');

        fprintf(fid, Data);
        
        fclose(fid);
    
    elseif val(i).protocol_name == "UART"
        data_bits = val(i).parameters.data_bits;
        stop_bits = val(i).parameters.stop_bits;
        parity = val(i).parameters.parity;
        bit_duration_uart = val(i).parameters.bit_duration;
  
        Time=0:bit_duration_uart:15*bit_duration_uart;

        overhead_arr_uart=[];

        total_tx_time_uart_arr=[];
        %convert txt to binary
        fid =fopen('data.txt');
        x_uart=fread(fid,'* char');

        for c=1:100
    
            if c>1
       
                x_uart=[x_uart ;x_uart(1:1,:)]; 
    
            end
            
            binary_uart= dec2bin(x_uart,8);
            binary_t_uart = transpose(binary_uart);
            binary_f_uart=flip(binary_t_uart);
            data_bin_uart=binary_f_uart(:)-'0';
            len_of_bits_uart=length(data_bin_uart);
            %UART
            overhead_uart=0;
            i_uart=1;
            j_uart=1;
            counter_uart=0;

            if data_bits==8
    
                num_uart=len_of_bits_uart/8;

            else        
                if rem(len_of_bits_uart,7)>0   
                    num_uart=floor(len_of_bits_uart/7)+1;    
                else
                    num_uart=floor(len_of_bits_uart/7);
                end
                
            end
            
            for n =1:num_uart
   
                trans_data(i_uart)=0;
                overhead_uart=overhead_uart+1;
                i_uart=i_uart+1;
   
                for m=1: data_bits
      
                    if j_uart<=len_of_bits_uart
    
                        trans_data(i_uart) =  data_bin_uart(j_uart);
     
                        if data_bin_uart(j_uart)==1
      
                            counter_uart=counter_uart+1;
      
                        end
                        
                        i_uart=i_uart+1;     
                        j_uart=j_uart+1;
      
                    end
                    
                end
                
                if parity== "even"
      
                    overhead_uart=overhead_uart+1;
                    modu=mod(counter_uart,2);
                    counter_uart=0;
    
                    if modu==0
        
                        trans_data(i_uart)=0;        
                        i_uart=i_uart+1;
                        counter_uart=0;
   
                    else
                        
                        trans_data(i_uart)=1;
                        i_uart=i_uart+1;
    
                    end
                    
                elseif parity== "odd"
       
                    overhead_uart=overhead_uart+1;
                    modu=mod(counter_uart,2);
    
                    if modu==0
        
                        trans_data(i_uart)=1;
                        i_uart=i_uart+1;
   
                    else
                        
                        trans_data(i_uart)=0;        
                        i_uart=i_uart+1;
    
                    end                 
                    
                end
                
                for nn=1:stop_bits
       
                    trans_data(i_uart)=1;
                    i_uart=i_uart+1;
                    overhead_uart=overhead_uart+1;
   
                end
                
            end
            
            ii=1;
            %drawing 2 packets

            if c==1

                for k=1:16

                    trans_data2 (ii) = trans_data(ii);
                    ii=ii+1;

                end
                
                figure
                stairs(Time,trans_data2);
                xlabel('Time');
                ylabel('Transsmitted Data');
                ylim([-1 2]);

            end
            
            total_tx_time_uart= bit_duration_uart*length(trans_data);
            total_tx_time_uart_arr=[total_tx_time_uart_arr total_tx_time_uart];
            percentage_of_overhead_uart=(overhead_uart/length(trans_data))*100;
            
            overhead_arr_uart=[overhead_arr_uart percentage_of_overhead_uart]; 
            efficiency_uart=100-overhead_arr_uart(:,1);
            
        end
        fid = fopen('output.json','w');
            
        jsonstruct(2).protocol_name = "UART";
        jsonstruct(2).outputs.total_tx_time = total_tx_time_uart_arr(:,1);
        jsonstruct(2).outputs.overhead = percentage_of_overhead_uart(:,1);
        jsonstruct(2).outputs.efficiency = efficiency_uart;

        jsonData = jsonencode(jsonstruct);

        Data = strrep(jsonData, ',', ',\n');

        Data = strrep(Data, '{', ',{\n');

        fprintf(fid, Data);

        fclose(fid);

        figure
        plot(overhead_arr_uart);
        xlabel('File Size');
        ylabel('overhead');
        figure
        plot (total_tx_time_uart_arr);
        xlabel('File Size');
        ylabel('Total Transmission Time');

    else
        disp(['Invalid Protocol ', val(i).protocol_name]);
    end

end


