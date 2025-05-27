## FUEL实机部署实验

本教程内提供的FUEL已经配置好实机话题参数，不需要修改，如果需要仿真的话，请使用港科大原版或自主修改配置文件

### 设备选型
- 机载电脑：香橙派5B
- 深度相机：Realsense D435
- 激光雷达：Livox Mid360（不做要求，FUEL支持激光雷达点云输入，如果有的话可以尝试一下）
- 飞控：Holybro_kakuteH7_mini
- 电调：四合一飞塔电调
- 机架建议选择轴距250的，并且配套购买，一般都有桨叶和电机配套，桨叶建议多买几套，机架也是，炸鸡坏了可以换
- 电池：格氏4S电池，建议买多几根，换用方便
- 充电器，建议买能够智能识别电芯数量自动启停断电的
- 总共费用大概在3000元左右，飞控等硬件需要手动焊接，建议做好功课再动手
### nlopt 安装
- 参考港科大FUEL中的nlopt安装流程，不需要clone其FUEL源码

### 下载zqu_fuel_ws，只适合ubuntu20.04
- https://github.com/1OngJ/zqu_fuel_ws.git
- cd zqu_fuel_ws
- catkin_make

### MAVROS安装
- MAVROS用于机载电脑与无人机间通讯，终端输入 ：sudo apt-get install ros-noetic-mavros ros-noetic-mavros-extras 安装功能包
- 安装后输入：roslaunch mavros px4.launch 以测试是否安装成功
- 机载电脑连接飞控后，输入上面的指令，即可以接收到飞控发布的IMU等数据话题。

### 深度相机或单目相机ROS驱动安装
- 本项目以Intel Realsense D435相机为例
- 下载librealsense，进入该目录，执行以下指令（此步只是为了安装viewer，对实际无影响，选装）
```
sudo apt-get install libudev-dev pkg-config libgtk-3-dev
sudo apt-get install libusb-1.0-0-dev pkg-config
sudo apt-get install libglfw3-dev
sudo apt-get install libssl-dev
sudo cp config/99-realsense-libusb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && udevadm trigger 
mkdir build
cd build
cmake ../ -DBUILD_EXAMPLES=true
make
sudo make install
```
- 安装后输入realsense-viewer 出现驱动应用界面即为安装成功。
- 以下为ROS下realsense camera的安装方法
```
sudo apt-get install ros-$ROS_DISTRO-realsense2-camera
sudo apt-get install ros-$ROS_DISTRO-realsense2-description
```
- 安装后在终端输入：
- roslaunch realsense2_camera rs_camera.launch
- 此命令用于启动D435的ROS驱动，且需要修改launch文件中的配置参数，启用align_depth infra_image depth_image 且将image输出的帧率设置为15、30或60，根据机载电脑配置酌情选择，建议15
- 配置文件中若需要关闭配置，将参数替换为-1即可



### VINS-FUSION部署
- 本项目中VINS-FUSION使用无人机IMU话题+深度相机双目话题作为输入，不推荐使用深度相机的IMU，效果很差。
- VINS部署可参考港科大github中内容：https://github.com/HKUST-Aerial-Robotics/VINS-Fusion
- 可能会遇到安装编译过程中OpenCV报错的问题，原因可能是ROS1自带的OpenCV库和VINS需要的CV库版本不一致冲突，解决可参考：https://blog.csdn.net/wyr1849089774/article/details/129907177
- 编译通过后执行：
```
roslaunch vins vins_rviz.launch
rosrun vins vins_node ~/catkin_ws/src/VINS-Fusion/config/euroc/euroc_stereo_imu_config.yaml
```
- 第二条指令的yaml文件可以自己编写，需要将无人机的IMU与深度相机infra1和infra2的图像话题作为输入
- 文件内还有相机的内参和外参，内外参的调节也可参考Fast Drone 250课程内的第十课，讲述得很详尽
- 执行完vins_node节点后，会发布vins相关的话题，本项目内使用的话题为/vins_fusion/imu_propagate，留意这个话题即可

### 飞控固件编译与地面站安装
- 地面站推荐使用QGroundControl，飞控固件推荐使用1.14.0或1.14.3，高版本固件不太稳定，会出现问题
- QGC下载地址：https://github.com/mavlink/qgroundcontrol/releases
- 在releases中选择系统对应的安装包进行下载安装
- 飞控固件：https://github.com/PX4/PX4-Autopilot
- 使用git clone -b release/1.14 https://github.com/PX4/PX4-Autopilot.git
- 下载后终端内执行
```
cd PX4-Autopilot
make px4_fmu-v5_default
```
- make需要选择对应型号的飞控板，例如本项目使用无人机的飞控板型号为：Holybro_kakuteH7_mini，make也对应这个型号
- make结束后，只需在第二条指令后加入 upload 字段，即可执行烧录，前提是电脑需要通过usb线接上飞控
- 烧录后启动QGC，按照软件指引配置电机和机架型号，这里不过多赘述。

### 地面站参数设置
- 找到EKF2_CV_CTRL 参数全部勾上，保存后参数显示应为15
- 找到EKF2_HGT_MODE,修改为vision,保存
- 以上修改完成后，重启飞控

### 启动流程
- 如果以上设置没有问题的话，先启动vins，并通过roslaunch vins rviz.launch来查看里程计是否正确
- 启动vins_to_mavros节点，将vins发布的消息格式转换为px4接收格式的数据
```
使用
rostopic echo /mavros/vision_pose/pose //如果没有这一话题，重装ros-noetic-mavros-extras功能包
rostopic echo /locol_position/pose
查看两个话题发布的x y z信息是否一致
上面的话题是vins发布并转换后的消息
下面的话题是飞控EKF2融合后的话题
一致即为融合成功
```
- 到这一步，可以先将无人机拿起缓慢行走一圈放回原地，若话题中数据没有明显的变化（±0.3为正常范围），即可解锁无人机切换自稳飞到1m高度，切换为定高或定点，如果定高可以保持高度，定点可以保持定位，那么即为成功
- 接下来可以执行
```
roslaunch exploration_manager exploration.launch
rosrun exploration_manager fuel_nav
```
- 执行节点后，将无人机解锁并切换到offborad模式，无人机会自动起飞至1m高度，在rviz打点，即可触发自主探索

- 在exploration.launch文件中，修改以下参数可以调整无人机的探索范围
```
<arg name="box_min_x" value="-25.0"/>
<arg name="box_min_y" value="-25.0"/>
<arg name="box_min_z" value=" -0.8"/>
<arg name="box_max_x" value="25.0"/>
<arg name="box_max_y" value="25.0"/>
<arg name="box_max_z" value=" 2.0"/>
```

# 如果还有什么问题的话，可以联系：sthfornil@foxmail.com




