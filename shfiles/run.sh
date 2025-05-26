roslaunch realsense2_camera rs_camera.launch & sleep 5;
roslaunch mavros px4.launch & sleep 5;
roslaunch vins fast_drone_250.launch & sleep 3;
rosrun mavros mavcmd long 511 105 5000 0 0 0 0 0
rosrun mavros mavcmd long 511 31  5000 0 0 0 0 0
#roslaunch exploration_manager exploration.launch;
wait;
