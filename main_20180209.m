% XY 坐标在1200dpi图片上 单位是像素（可以根据实际像素进行缩小 手机截图是倍率是 数据xy/128 *6）
% 时间 每笔的初始化时间为0 us ，可以认为第一个数据为开始值。
% 
% 数据格式：(最后)
% 时间(us) xy坐标 压力状态(1/0:1代表有压力) 数据是否有效

%% 2018.02.21 对于数据11，先
clc
clear all
close all

data_raw = load('./data/11/data.txt')';
data_raw(3, :) = -data_raw(3, :); % 为方便画图，图像的坐标系转换
timestamp_raw = data_raw(1, :)/1000;  %ms;
xy_raw = data_raw( 2:3, :);
pressure_raw = data_raw(4, :);
xy_state_raw = data_raw(5, :); % 图像解码是否有输出数据

is_new_beginning = 0; % 通过压力值来判断是否是新的笔画

%% 1.做数据分割
new_beginning_counter = 0;
% data_spreate % 分割的数据
j_spreate = 0; % 代表分离的笔划
i_count = 0;
data_length = length(timestamp_raw);
for i = 1:data_length
    if pressure_raw(i) == 1 
       i_count = i_count + 1; % 一个连划里面的点计数
       data_spreate_tmp(:, i_count) = data_raw(:, i);
    else
        j_spreate = j_spreate + 1; % 新的一个连划
        data_spreate{j_spreate} = data_spreate_tmp;
        clear data_spreate_tmp;
        i_count = 0;
    end
end

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
plot(xy_raw(1,1:1200), xy_raw(2,1:1200), '.');
grid on;


    
