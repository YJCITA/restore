clc
clear 
close all

data_addr = './data/11/';
raw_data_addr = [data_addr, 'data.txt'];
data_raw_tmp = load(raw_data_addr)';
data_raw1 = data_raw_tmp;
data_raw1(1, :) = data_raw1(1, :)/1e6;  %将us转换为s;
data_raw1(3, :) = -data_raw1(3, :); % 为方便画图，图像的坐标系转换
%% 1.做数据分割
% data_spreate % 分割的数据
[data_raw, data_spreate, j_spreate_debug] = data_timestamp_trans(data_raw1, 1);

new_data_addr = [data_addr, 'data_new.txt'];
dlmwrite( new_data_addr, data_raw', ' ');