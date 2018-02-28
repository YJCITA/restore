% 思路
%  每M（7）个数据，利用中值滤波去除野值，
%  然后再计算均值mean,均方差Std,基于正态分布假设进行野值检测
function [data_out, ret_state] = outliter_delete( data_in )
    M_step = 5;
    i_save = 0;
    [t, length_in] = size(data_in);
    
    if length_in == 7
        test = 1;
    end
    
    data_in_x = data_in(2, :);
    data_in_y = data_in(3, :);
    if length_in >= M_step
        is_first_init = true;
        for i = 1:length_in
            if i >= M_step
                % 通过中值滤波，计算均值，均方差
                if_have_outlier = true;
                loop_counter = 0;
                data_filter_x = data_in_x(i-M_step+1:i);
                data_filter_y = data_in_y(i-M_step+1:i);
                while if_have_outlier
                    if_have_outlier = false;
                    data_filter_x = medfilt1(data_filter_x, 3);
                    data_filter_y = medfilt1(data_filter_y, 3);
                    meanX = mean(data_filter_x);
                    stdX = std(data_filter_x);
                    meanY = mean(data_filter_y);
                    stdY = std(data_filter_y);
                    % 判断两两之间是否有很大的值
                    for kk = 2:M_step
                        diff_x = abs(data_filter_x(kk) - data_filter_x(kk-1));
                        diff_y = abs(data_filter_y(kk) - data_filter_y(kk-1));
                        if diff_x > 2000 || diff_y > 2000
                            if_have_outlier = true;
                            continue;
                        end
                    end
                    
                    loop_counter = loop_counter + 1;
                    if loop_counter >=3
                        if_have_outlier = false;
                    end
                end
                
                %剔除野值
                data_cur = data_in(:, i-M_step+1);
                x_cur = data_cur(2);
                y_cur = data_cur(3);
                if abs(x_cur - meanX) < 2000 &&  abs(y_cur - meanY) < 2000
%                 if abs(x_cur - meanX) < 5*stdX &&  abs(y_cur - meanY) < 5*stdY
                    i_save = i_save + 1;
                    data_out(:, i_save) = data_cur;
                end
                %clear data_filter_x  data_filter_y;
            end
            
            if i == length_in
                % 数据执行到最后一个，但是最后M_step-1位还是没有处理的
                for j = length_in-M_step+1:length_in
                    data_cur = data_in(:, j);
%                     if abs(x_cur - meanX) < 5*stdX &&  abs(y_cur - meanY) < 5*stdY
                    if abs(x_cur - meanX) < 2000 &&  abs(y_cur - meanY) < 2000
                        i_save = i_save + 1;
                        data_out(:, i_save) = data_cur;
                    end
                end
            end

        end
        
        ret_state = 1;
    else
        ret_state = -1;
        data_out = ones(5,1);
    end
    
end

