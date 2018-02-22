% 判断数据的合理性
% data_in: [time x y]
% ret_state:
%           1: 数据有正常结果
%           -1：输入数据太少
%           -2: 有效数据太少，不稳定
function [ data_out, ret_state ] = fun_judge_data( data_in )
    [t, length_t] = size(data_in);
    i_data_in_new = 0;
    i_data_xy = 1;
    save_data_xy(:, 1) = [data_in(:, 1); sqrt(data_in(2, 1)^2 + data_in(3, 1)^2)];
    save_data_V = [];
    is_first_data = true; % 用于挑选data_in_new
    if length_t <= 3
        data_out = data_in;
        ret_state = -1;
    else
        % 计算速度
        for i=2:length_t
            dt = data_in(1, i) - data_in(1, i-1);
            dxy = data_in(2:3, i) - data_in(2:3, i-1);
            if dt > 0
                Vxy = dxy/dt;
            else
                Vxy = [0, 0]';
            end
            V = sqrt(Vxy(1)^2 + Vxy(2)^2);
            % 速度大于某个值，则这个数据作废
%             if V < 1e5
                % 如果是第一个数据
%                 if i == 2
%                     data_in_new = data_in(:, 1);
%                 end
                t1 = [data_in(1, i-1), Vxy(1), Vxy(2), V, dt]';
                save_data_V = [save_data_V t1];
                
                i_data_xy = i_data_xy + 1;
                save_data_xy(: ,i_data_xy) = [data_in(:, 1); sqrt(data_in(2, i)^2 + data_in(3, i)^2)];
                
                i_data_in_new = i_data_in_new + 1;
                data_in_new(:, i_data_in_new) =  data_in(:, i);
%             end
        end
        
%         data_in_new = data_in;
        % 判断数据的有效性
        % 判断依据： 1. x - mean > 3var
        mean_V = mean(save_data_V(4, :));
        % 平均速度不能超过1e5
        V_all = save_data_V(4, :);
        xy_all = save_data_xy(4, :);
        sum_V = sum(V_all);
        save_remove_V = [];
        V_all_new = V_all;
        xy_all_new = xy_all;
        while mean_V > 1e5
            V_all_tmp = [];
            xy_all_tmp = [];
            for i = 1:length(V_all_new)
                if V_all_new(i) == max(V_all_new)
                    save_remove_V = [save_remove_V max(V_all_new)]; % 删除这个最大值
                else
                    V_all_tmp = [V_all_tmp V_all_new(i)]; 
                    xy_all_tmp = [xy_all_tmp V_all_new(i)]; 
                end
            end
            V_all_new = V_all_tmp;
            xy_all_new = xy_all_tmp;
            mean_V = mean(V_all_new);
        end
        new_V_t = V_all_new - mean_V; % 去均值后的V
        var_newV = std(new_V_t);
        
               
        mean_xy_nor = mean(xy_all_new);
        new_xy_nor = xy_all_new - mean_xy_nor;% 去均值
        var_new_xy_nor = std(new_xy_nor);
        
        [t, length_t_new] = size(data_in_new);
        for i = 1:length_t_new-1
            diff_v = V_all(i) - mean_V;
            diff_xy_nor = xy_all(i) - mean_xy_nor;
            
            if abs(diff_v) > 3*var_newV || V >1e5 || abs(diff_xy_nor) > 3*var_new_xy_nor
                v_state(i) = 0; 
            else
                v_state(i) = 1; 
            end
        end
        % 判断正常的速度数据个数，如果<70%,则有问题
        num_legal_data = sum(v_state);
        data_in_state = ones(length_t_new, 1); % 初始化认为所有数据都是正常的
        if num_legal_data > (length_t_new - 1) * 0.7
            for i = 1:length_t_new-1
                if v_state(i) == 0
                    % 如果数据异常
                    if i == 1
                        % 第一个V，所以跟第二V比
                        if v_state(i+1) == 1
                            % 如果第二个V正常，则说明第一个xy异常
                            data_in_state(1) = 0;
                            data_in_state(2) = 1;
                        else
                            % 如果第二个V也不正常，则说明第1,2的xy都异常（不完备，近视处理）
                            data_in_state(1) = 0;
                            data_in_state(2) = 0;
                        end
                    elseif i == length_t_new - 1
                        % 如果是最后一个数据，则跟前一个V比较
                        if v_state(i-1) == 1
                            % 如果前一个V正常，则说明最后一个xy异常
                            data_in_state(length_t_new) = 0;
                            data_in_state(length_t_new-1) = 1;
                        else
                            % 如果前一个V也不正常，则说明最后两个xy都异常（不完备，近视处理）
                            data_in_state(length_t_new) = 0;
                            data_in_state(length_t_new-1) = 0;
                        end
                    else
                        % 其他中间数据，则跟前后的V比较
                        v_stata_pre = data_in_state(i - 1); 
                        v_stata_next = data_in_state(i + 1);
                        if v_stata_pre == 1 && v_stata_next == 0
                            data_in_state(i+1) = 0;
                        elseif v_stata_pre == 0 && v_stata_next == 1
                            data_in_state(i) = 0;
                        elseif v_stata_pre == 0 && v_stata_next == 0
                            data_in_state(i+1) = 0;
                            data_in_state(i) = 0;
                        end
                    end
                end
            end
            
            % 数据都判断完毕
            for i = 1:length_t_new
                data_state_cur = data_in_state(i);
                if data_state_cur == 1
                    data_out(:, i) = data_in_new(:, i);
                end
            end
            ret_state = 1;
        else
            ret_state = -2;
            data_out = data_in;
        end
        
    end


end

