onerror {resume}
add wave -noupdate -expand -group DUT *

#add wave -position end  /e_selftesttopqualification_tb/i_DUT/i_SelfTest/p_SelfTestFsm/v_State_i
#add wave -position end  /e_selftesttopqualification_tb/i_DUT/i_SelfTestWdt/p_SingleProcessFsm/v_State_i
#add wave -position end  /e_selftesttopqualification_tb/i_DUT/i_SelfTestOlt/p_OltFsm/v_State_i

#add wave -position end  /e_ads1018sequencerqualification_tb/i_DUT/p_Fsm/v_State_i

dataset snapshot -size 100 -mode cumulative -filemode overwrite -file vsim_snapshot