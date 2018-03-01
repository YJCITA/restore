function [data_out, ret_state] = fun_mdfilter(data_in, med_length)
    [t, data_in_length] = size(data_in);
    if data_in_length > med_length
        for i = 1:data_in_length
            if i >= med_length 
                data_array = data_in(i-med_length+1 : i);
                med_tmp = median(data_array);
                if i == med_length
                    % 头几个数据
                    data_out(1:med_length) = med_tmp;
                else
                    data_out(i) = med_tmp;
                end
            end
        end
        ret_state = 1;
    else
        ret_state = -1;
        data_out = data_in;
    end
end

