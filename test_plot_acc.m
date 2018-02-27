% XY 坐标在1200dpi图片上 单位是像素（可以根据实际像素进行缩小 手机截图是倍率是 数据xy/128 *6）
% 时间 每笔的初始化时间为0 us ，可以认为第一个数据为开始值。
% 
% 数据格式：(最后)
% 时间(us) acc(xyz,4096=1G) xy坐标 压力状态(1/0:1代表有压力) 数据是否有效

%% 2018.02.21 对于数据11，先对前1200个数据(第一句诗进行处理)
clc
clear 
close all
% time acc(xyz) xy state1 2
data_raw_tmp = load('./data/数据格式+time+xyz+decode+xy_20180227.txt')';
data_raw1 = data_raw_tmp(:, 1:500);
data_raw1(1, :) = data_raw1(1, :)/1e6;  %将us转换为s;
data_raw1(6, :) = -data_raw1(6, :); % 为方便画图，图像的坐标系转换

[data_raw] = data_timestamp_trans(data_raw1);

timestamp_raw = data_raw(1, :);  %s;
acc_raw = data_raw(2:4, :);  % acc 

length1 = length(data_raw);
for i= 1:length1
    t1 = sqrt(sum(acc_raw(:, i).^2));
    acc_normal(:, i) = [timestamp_raw(i), t1]';
end

xy_raw = data_raw(5:6, :);
pressure_raw = data_raw(7, :);
xy_state_raw = data_raw(8, :); % 图像解码是否有输出数据



% 原始点云
figure()
subplot(2,1,1)
hold on;
plot(timestamp_raw, acc_raw(1, :));
plot(timestamp_raw, acc_raw(2, :));
plot(timestamp_raw, acc_raw(3, :));
grid on;
legend('x', 'y', 'z');

subplot(2,1,2)
hold on;
plot(acc_normal(1,:), acc_normal(2, :));
grid on;
legend('acc-nor');



    
