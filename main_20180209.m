% XY 坐标在1200dpi图片上 单位是像素（可以根据实际像素进行缩小 手机截图是倍率是 数据xy/128 *6）
% 时间 每笔的初始化时间为0 us ，可以认为第一个数据为开始值。
% 
% 数据格式：(最后)
% 时间(us) xy坐标 压力状态(1/0:1代表有压力) 数据是否有效

%% 2018.02.21 对于数据11，先对前1200个数据(第一句诗进行处理)
clc
clear all
close all

data_raw_tmp = load('./data/11/data.txt')';
data_raw = data_raw_tmp; %(:, 1:7000);
data_raw(1, :) = data_raw(1, :)/1e6;  %将us转换为s;
data_raw(3, :) = -data_raw(3, :); % 为方便画图，图像的坐标系转换

timestamp_raw = data_raw(1, :);  %s;
xy_raw = data_raw( 2:3, :);
pressure_raw = data_raw(4, :);
xy_state_raw = data_raw(5, :); % 图像解码是否有输出数据

is_new_beginning = 0; % 通过压力值来判断是否是新的笔画

%% 1.做数据分割
new_beginning_counter = 0;
% data_spreate % 分割的数据
j_spreate = 0; % 代表分离的笔划
i_count = 0;
time_base = 0; % 因为目前时间戳不是从一开机就连续增加的，而是每次检测到压力开机后才开始计时，所以为了分析方便，做累加
data_length = length(timestamp_raw);
time_pre = 0;
for i = 1:data_length
    xy_state_cur = xy_state_raw(i);
    pressure_cur = pressure_raw(i);
    data_cur = data_raw(:, i);
    if i == 145
        test = 1;
    end
    
    if xy_state_cur == 1 && pressure_cur == 1 % 只有当图像解算坐标值有效,并且有压力值时才记为有效数据
        % 说明数据从无效重新变为有效(有可能是)
        if i_count == 0
            time_base = time_base + time_pre;
            clear data_spreate_tmp;
        end
        i_count = i_count + 1; % 一个连划里面的点计数
        data_spreate_tmp(:, i_count) = data_cur;
        data_spreate_tmp(1, i_count) = data_spreate_tmp(1, i_count) + time_base; % 累加时间
        
    end
    
    % 当压力值变为0，同时累积的数据大于0个，则存储
    if pressure_cur == 0 && i_count > 0
        j_spreate = j_spreate + 1; % 新的一个连划
        data_spreate{j_spreate} = data_spreate_tmp;
        time_pre = data_cur(1);
        i_count = 0;
    end
    

end

%% 根据速度剔除异常值，新的有效数据都在data_new中
% 新数据data_new =[time xy*2 vxy*2 is_new_trace(是否是新的连笔)]
i_save = 0;
j_data_new = 0; % 重构数据，剔除异常值
% data_new; % 新的数据
for i=1:j_spreate
    if i == 4
        test = 1;
    end
    data_tmp = data_spreate{i};
    [t, data_length1] = size(data_tmp);
    is_first_data = true;
    for j = 1:data_length1
        time_cur = data_tmp(1, j);
        xy_cur = data_tmp(2:3, j);
        if is_first_data
            % 首次进入函数，需要初始化pre的值
            time_pre = time_cur;
            xy_pre = xy_cur;
            is_first_data = false;
            
            % 保存新连笔的第一个数据
            j_data_new = j_data_new + 1;
            % 初始第一个数据速度为0
            data_new(:, j_data_new) = [time_cur, xy_cur(1), xy_cur(2), 0, 0, 1]';
        else
            dt = time_cur - time_pre;
            if dt > 0.2
                test = 1;
            end
            dxy = xy_cur - xy_pre;
            dxy_normal = sqrt(dxy(1)^2 + dxy(2)^2);
            % dt太大的数据直接抛弃
            % TODO：因为有些时候可能是第一个数据是错的，所以才需要回朔删除第一个数据，将第二个数据当做第一个数据的备选
            if dt > 0 && dt < 0.2 
                v_xy = dxy/dt; 
                v_normal = sqrt(v_xy(1)^2 + v_xy(2)^2); % 速度模值
                % ---TODO---
                % 书写速度的阈值，这个可以先这么简单处理，更合理是考虑历史速度，剔除突变
                if v_normal < 1e5 
                    time_pre = time_cur;
                    j_data_new = j_data_new + 1;
                    % 剔除异常值后，所有有效数据都在data_new中
                    data_new(:, j_data_new) = [time_cur, xy_cur(1), xy_cur(2), v_xy(1), v_xy(2), 0]';
            
                    i_save = i_save + 1;
                    save_v_xy(:, i_save) = [time_cur, v_xy(1), v_xy(2)]';
                    save_v(:, i_save) = [time_cur, v_normal]';
                    save_xy(:, i_save) = [time_cur, xy_cur(1), xy_cur(2)]';
                    save_dxy_nor(:, i_save) = [time_cur, dxy_normal]';
                    save_dt(:, i_save) = [time_cur, dt]';
                end
            else
                time_pre = time_cur;
%                 printf('error dt = %f\n', dt);
            end
        end
    end
end

%% 笔迹还原
% data_new =[time xy*2 vxy*2 is_new_trace(是否是新的连笔)]
% 直接用速度做插值
[t, length_new] = size(data_new);
i_save = 0;
for i = 1:length_new
    time_cur = data_new(1, i);
    xy_cur = data_new(2:3, i);
    Vxy_cur = data_new(4:5, i);
    is_new_trace = data_new(6, i);
    if is_new_trace == 1
        time_pre = time_cur;
        xy_pre = xy_cur;
        Vxy_pre = Vxy_cur;      
        
        % 保存数据
        i_save = i_save + 1;
        data_restore(:, i_save) = [time_cur, xy_cur(1), xy_cur(2), 1]';
    else
        dt = time_cur - time_pre;
        % 插值
        dt_insert = 1/800; % 400hz
        for j = 1 : dt/dt_insert % 400hz
            dt1 = j*dt_insert;
            Vxy_cur = (xy_cur - xy_pre)/dt;
            xy_insert = xy_pre + Vxy_cur*dt1;
            time_cur_new = time_pre + dt1;
            i_save = i_save + 1;
            data_restore(:, i_save) = [time_cur_new, xy_insert(1), xy_insert(2), 0]';
        end
        time_pre = time_cur;
        xy_pre = xy_cur;
        Vxy_pre = Vxy_cur; 
    end
end



%% 画图
figure()
hold on;
grid on;
plot(save_v_xy(1,:), save_v_xy(2,:), '.r'); % vx
plot(save_v_xy(1,:), save_v_xy(3,:), '*'); % vy
plot(save_v(1,:), save_v(2,:)); % v
legend('vx', 'vy', 'v');

figure()
hold on;
grid on;
plot(save_dxy_nor(1,:), save_dxy_nor(2,:), '.r'); % dxy_nor
legend('dxy-nor');

figure()
hold on;
grid on;
plot(save_xy(1,:), save_xy(2,:), '.r'); % x
plot(save_xy(1,:), save_xy(3,:), '*'); % y
legend('x', 'y');

figure()
hold on;
grid on;
plot(data_new(2,:), data_new(3,:), '.'); % xy
% xlim([3000, 9000]);
% ylim([-5000, -2000]);
legend('new-xy');

figure()
hold on;
grid on;
plot(data_restore(2,:), data_restore(3,:), '.'); % xy-restore
% xlim([3000, 9000]);
% ylim([-5000, -2000]);
legend('xy-restore');

% figure()
% hold on;
% grid on;
% plot(save_dt(1,:), save_dt(2,:), '.'); % dt
% legend('dt');

% 统计直方图
% figure()
% subplot(2,1,1);
% hist(save_v_xy(2,:), 50);
% legend('vx');
% 
% subplot(2,1,2);
% hist(save_v_xy(3,:), 50);
% legend('vy');

% 对分割出来的连划进行分析
% for i = 20:-1:1
%     data_tmp = data_spreate{i};
%     data_tmp_size = size(data_tmp);
%     if data_tmp_size(2) > 3
%         figure(i)
%         plot(data_tmp(2,:), data_tmp(3,:), '.');
%         grid on;
%         xlim([0, 35000]);
%         ylim([-35000, 0]);
%         title(i);
%     end
% end

% data_length = length(timestamp_raw);
% for i = 1:data_length
%     if pressure_raw(i) == 1 
%         new_beginning_counter = new_beginning_counter + 1;
%         if( i > 1 && xy_state_raw(i) == 1 && is_new_beginning == 0 && new_beginning_counter > 1)
%             i_count = i_count + 1;
%             dt_save(i_count) = timestamp_raw(i) - timestamp_raw(i - 1);
%         else
%             dt_save(i) = -1;
%         end
%         is_new_beginning = 0;
%     else
%         is_new_beginning = 1; % 这是新的笔画开始
%         new_beginning_counter = 0;
%         dt_save(i) = -1;
%     end
% end




%%
% % dt
% figure()
% plot(dt_save);
% grid on;
% legend('dt(ms)');
% 
% 原始点云
figure()
plot(xy_raw(1,:), xy_raw(2,:), '.');
grid on;
% xlim([3000, 9000]);
% ylim([-5000, -2000]);
title('raw-data')


    
