% XY 坐标在1200dpi图片上 单位是像素（可以根据实际像素进行缩小 手机截图是倍率是 数据xy/128 *6）
% 时间 每笔的初始化时间为0 us ，可以认为第一个数据为开始值。
% 
% 数据格式：(new)
% 时间(us) xy坐标 压力状态(1/0:1代表有压力) 数据是否有效
% 2018.02.25 对数据进行一次差分，然后中值滤波，再用积分还原
% 2018.02.28 重新思考处理逻辑：
%  1.去除野值(用中值的策略，选取去掉野值的数据计算均值和方差，然后用这个做标准剔除野值；不能一直用中值滤波，因为笔画有些时候很稀疏)
%  2.笔画分割，连接/插值
% TODO： 目前初步剔除野值的效果还可以，按时得继续分析下为什么有些点被误删除，有些没删除

%% 2018.02.21 对于数据11，先对前1200个数据(第一句诗进行处理)
clc
clear 
close all

data_raw_tmp = load('./data/11/data.txt')';
data_raw1 = data_raw_tmp(:, 1:end);
data_raw1(1, :) = data_raw1(1, :)/1e6;  %将us转换为s;
data_raw1(3, :) = -data_raw1(3, :); % 为方便画图，图像的坐标系转换
%% 1.做数据分割
% data_spreate % 分割的数据
[data_raw, data_spreate, j_spreate_debug] = data_timestamp_trans(data_raw1, 0);

timestamp_raw = data_raw(1, :);  %s;
xy_raw = data_raw( 2:3, :);
pressure_raw = data_raw(4, :);
xy_state_raw = data_raw(5, :); % 图像解码是否有输出数据
is_new_beginning = 0; % 通过压力值来判断是否是新的笔画

%% 根据速度剔除异常值，新的有效数据都在data_new中
% 新数据data_new =[time xy*2 vxy*2 is_new_trace(是否是新的连笔)]
i_save = 0;
j_data_new = 0; % 重构数据，剔除异常值
j_spreate_count = 0;
% data_new; % 新的数据
j_spreate = length(data_spreate);
for i_loop=1:j_spreate
    data_tmp = data_spreate{i_loop};
    if i_loop == j_spreate_debug
        test = 1;
    end
         
    [data_filter, ret_state] = outliter_delete( data_tmp );
    if ret_state >= 1
        data_spreate_tmp = data_filter;
        j_spreate_count = j_spreate_count + 1;
        data_spreate_filter{j_spreate_count} = data_spreate_tmp;

        if 0
            figure(1)
            hold on;
            subplot(1,2,1)
            hold on;
            grid on;
            plot(data_tmp(2,:), data_tmp(3,:), '.b'); % xy
            legend('xy-raw');

            subplot(1,2,2)
            hold on;
            grid on;
            plot(data_filter(1,:), data_filter(2,:), '.b'); % xy
            legend('xy-filter');

            % 测试
            figure(2)
            hold on;
            subplot(2,2,1)
            hold on;
            grid on;
            plot(data_tmp(1,:), data_tmp(2,:), '.b'); % x
            legend('x');

            subplot(2,2,3)
            hold on;
            grid on;
            plot(data_tmp(1,:), data_tmp(3,:), '.b'); % y
            legend('y');

            subplot(2,2,2)
            hold on;
            grid on;
            plot(data_tmp(1,:), data_filter(1,:), '.b'); % x
            legend('x-filter');

            subplot(2,2,4)
            hold on;
            grid on;
            plot(data_tmp(1,:), data_filter(2,:), '.b'); % y
            legend('y-filter');
        end

        %%
        data_tmp = data_spreate_tmp; % 使用中值滤波的数据
        [t, data_length1] = size(data_tmp);
        is_first_data = true;
        new_first_data_judege_counter = 0;
        for j = 1:data_length1
            time_cur = data_tmp(1, j);
            xy_cur = data_tmp(2:3, j);
            if is_first_data            
                time_pre = time_cur;
                xy_pre = xy_cur;
                j_data_new = j_data_new + 1;
                data_new(:, j_data_new) = [time_cur, xy_cur(1), xy_cur(2), 0]';
                is_first_data = false;
            else
                dt = time_cur - time_pre;
                if j == 14
                    test = 1;
                end
                dxy = xy_cur - xy_pre;
                dxy_normal = sqrt(dxy(1)^2 + dxy(2)^2);
                % dt太大的数据直接抛弃
                % TODO：因为有些时候可能是第一个数据是错的，所以才需要回朔删除第一个数据，将第二个数据当做第一个数据的备选
                if dt > 0 && dt < 1
                    v_xy = dxy/dt; 
                    v_normal = sqrt(v_xy(1)^2 + v_xy(2)^2); % 速度模值
                    % ---TODO---
                    % 书写速度的阈值，这个可以先这么简单处理，更合理是考虑历史速度，剔除突变
                    if 1% v_normal < 100e5 
                        time_pre = time_cur;
                        j_data_new = j_data_new + 1;
                        % 剔除异常值后，所有有效数据都在data_new中
                        data_new(:, j_data_new) = [time_cur, xy_cur(1), xy_cur(2), 0]';

                        i_save = i_save + 1;
                        save_v_xy(:, i_save) = [time_cur, v_xy(1), v_xy(2)]';
                        save_v(:, i_save) = [time_cur, v_normal]';
                        save_xy(:, i_save) = [time_cur, xy_cur(1), xy_cur(2)]';
                        save_dxy_nor(:, i_save) = [time_cur, dxy_normal]';
                        save_dt(:, i_save) = [time_cur, dt]';
                    end
                else
                    time_pre = time_cur;
                end
            end
        end
    end
end

%% 笔迹还原
% data_new =[time xy*2 vxy*2 is_new_trace(是否是新的连笔)]
% 直接用速度做插值
[t, length_new] = size(data_new);
i_save_origin = 0;
i_save_insert = 0;
data_restore_origin = []; % 原始图像识别出来的坐标
data_restore_insert = []; % 插值的点

i_save = 0;
for i = 1:length_new
    time_cur = data_new(1, i);
    xy_cur = data_new(2:3, i);
    is_new_trace = data_new(4, i);
    if is_new_trace == 1
        time_pre = time_cur;
        xy_pre = xy_cur;   
        
        % 保存数据
        i_save = i_save + 1;
        data_restore(:, i_save) = [time_cur, xy_cur(1), xy_cur(2), 1]';
        i_save_origin = i_save_origin + 1;
        data_restore_origin(:, i_save_origin) = [time_cur, xy_cur(1), xy_cur(2), 1]';
    else
        % 保存数据
        i_save = i_save + 1;
        data_restore(:, i_save) = [time_cur, xy_cur(1), xy_cur(2), 1]';
        i_save_origin = i_save_origin + 1;
        data_restore_origin(:, i_save_origin) = [time_cur, xy_cur(1), xy_cur(2), 1]';
        
        dt = time_cur - time_pre;
        % 插值
        dxy = xy_cur - xy_pre;
        dxy_nor = sqrt(sum(dxy.^2));
        if dxy_nor < 250
            dt_insert = 1/800; % 400hz
            for j = 1 : dt/dt_insert % 400hz
                dt1 = j*dt_insert;
                Vxy_cur = dxy/dt;
                xy_insert = xy_pre + Vxy_cur*dt1;
                time_cur_new = time_pre + dt1;
                i_save = i_save + 1;
                data_restore(:, i_save) = [time_cur_new, xy_insert(1), xy_insert(2), 0]';
                i_save_insert = i_save_insert + 1;
                data_restore_insert(:, i_save_insert) = [time_cur_new, xy_insert(1), xy_insert(2), 0]';
            end
        end
        time_pre = time_cur;
        xy_pre = xy_cur;
    end
end



%% 画图

figure()
subplot(2,1,1)
grid on;
plot(data_raw(1,:), data_raw(2,:)); % x
legend('x');

subplot(2,1,2)
grid on;
plot(data_raw(1,:), data_raw(3,:)); % y
legend('y');
% 
% figure()
% hold on;
% grid on;
% plot(save_v_xy(1,:), save_v_xy(2,:), '.r'); % vx
% plot(save_v_xy(1,:), save_v_xy(3,:), '*'); % vy
% plot(save_v(1,:), save_v(2,:)); % v
% legend('vx', 'vy', 'v');
% 
figure()
hold on;
grid on;
plot(save_dxy_nor(1,:), save_dxy_nor(2,:), '.r'); % dxy_nor
legend('dxy-nor');
% 
% figure()
% hold on;
% grid on;
% plot(save_xy(1,:), save_xy(2,:)); % x
% plot(save_xy(1,:), save_xy(3,:)); % y
% legend('x', 'y');

figure()
hold on;
grid on;
plot(data_restore_insert(2,:), data_restore_insert(3,:), '.r'); % xy-restore-insert
plot(data_restore_origin(2,:), data_restore_origin(3,:), '.'); % xy-restore-origin
% xlim([3000, 9000]);
% ylim([-5000, -2000]);
legend('xy-restore-insert', 'xy-restore-origin');

figure()
hold on;
grid on;
plot(data_restore(2,:), data_restore(3,:), '.'); % xy-restore-origin
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
hold on;
grid on;
plot(xy_raw(1,:), xy_raw(2,:), '.r'); % raw
plot(data_new(2,:), data_new(3,:), '.'); % xy
legend('raw-xy', 'new-xy');



    
