% 1.时间戳转换（变成连续累加的时间戳）
% 2.连续笔画数据分割
function [data_out, data_spreate_out, j_spreate_debug] = data_timestamp_trans(data_in)
    new_time_base = false;
    i_count = 0;
    i_count_s = 0;
    j_spreate = 0; % 代表分离的笔划
    j_spreate_debug = -1; % 用于调试
    time_base = 0; % 因为目前时间戳不是从一开机就连续增加的，而是每次检测到压力开机后才开始计时，所以为了分析方便，做累加
    [size_vec, data_length] = size(data_in);
    time_pre = 0;
    for i = 1:data_length
        % 为了适配不同的数据长度
        if size_vec == 8
            pressure_cur = data_in(7,i);
            xy_state_cur = data_in(8,i);
        else
            pressure_cur = data_in(4,i);
            xy_state_cur = data_in(5,i);
        end
        data_cur = data_in(:, i);
        
        % 调试的代码
        if data_cur(2) == 4452 && data_cur(3) == -7456
            j_spreate_debug = j_spreate + 1;
            x_error = data_cur(2);
            y_error = data_cur(3);
            test = 1;
        end
        
        if xy_state_cur == 1 && pressure_cur == 1 % 只有当图像解算坐标值有效,并且有压力值时才记为有效数据
            % 说明数据从无效重新变为有效(有可能是)
            if new_time_base
                time_base = time_base + time_pre;
                clear data_spreate_tmp;
                new_time_base = false;
            end
            
            data_cur(1) = data_cur(1) + time_base; % 累加时间
            i_count = i_count + 1; % 连续计数
            data_out(:, i_count) = data_cur;
            
            i_count_s = i_count_s + 1; % 一个连划里面的点计数
            data_spreate_tmp(:, i_count_s) = data_cur;

        end

        % 当压力值变为0，同时累积的数据大于5个，则更新时间戳
        if pressure_cur == 0 && i_count_s > 5
            j_spreate = j_spreate + 1; % 新的一个连划
            i_count_s = 0;
            data_spreate_out{j_spreate} = data_spreate_tmp;
            time_pre = data_cur(1);
            new_time_base = true;
        end 
    end

end

