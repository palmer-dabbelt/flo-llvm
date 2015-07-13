#include "tempdir.bash"
#include "chisel-jar.bash"

TEST="Sum"

cat >$TEST.flo <<"EOF"
Sum::sreq::valid = in'1
Sum::sreq::bits::v = in'32
Sum::sreq::bits::len = in'32
Sum::mrsp::valid = in'1
Sum::mrsp::bits::tag = in'8
Sum::mrsp::bits::data = in'32
Sum::mreq::ready = in'1
Sum::srsp::ready = in'1
Sum::reset = rst'1
Sum::tmp6_0 = add'32 Sum::sum3 Sum::mrsp::bits::data
Sum::tmp6 = mov Sum::tmp6_0
Sum::tmp7_0 = lt'32 Sum::a1 Sum::ea2
Sum::tmp7 = mov Sum::tmp7_0
Sum::tmp8_0 = add'32 Sum::a1 1'32
Sum::tmp8 = mov Sum::tmp8_0
Sum::tmp9_0 = eq'8 Sum::num_reqs4 0'8
Sum::tmp9 = mov Sum::tmp9_0
Sum::tmp10_0 = add'32 Sum::sreq::bits::v Sum::sreq::bits::len
Sum::tmp10 = mov Sum::tmp10_0
Sum::sreq::ready_0 = eq'1 Sum::computing_5 0'1
Sum::sreq::ready = out'1 Sum::sreq::ready_0
Sum::mrsp::ready = out'1 1'1
Sum::mreq::valid_0 = mux'1 Sum::computing_5 Sum::tmp7 0'1
Sum::mreq::valid = out'1 Sum::mreq::valid_0
Sum::mreq::bits::wr_ = out'1 0'1
Sum::mreq::bits::tag = out'8 0'8
Sum::mreq::bits::addr_0 = mux'32 Sum::tmp7 Sum::a1 0'32
Sum::mreq::bits::addr_1 = mux'32 Sum::computing_5 Sum::mreq::bits::addr_0 0'32
Sum::mreq::bits::addr = out'32 Sum::mreq::bits::addr_1
Sum::mreq::bits::data = out'32 0'32
Sum::srsp::valid_0 = mux'1 Sum::tmp7 0'1 Sum::tmp9
Sum::srsp::valid_1 = mux'1 Sum::computing_5 Sum::srsp::valid_0 0'1
Sum::srsp::valid = out'1 Sum::srsp::valid_1
Sum::srsp::bits::data_0 = mux'32 Sum::tmp9 Sum::sum3 0'32
Sum::srsp::bits::data_1 = mux'32 Sum::tmp7 0'32 Sum::srsp::bits::data_0
Sum::srsp::bits::data_2 = mux'32 Sum::computing_5 Sum::srsp::bits::data_1 0'32
Sum::srsp::bits::data = out'32 Sum::srsp::bits::data_2
Sum::a1_0 = mux'32 Sum::computing_5 Sum::tmp8 Sum::sreq::bits::v
Sum::a1_1 = mux'1 Sum::tmp7 Sum::mreq::ready 0'1
Sum::a1_2 = mux'1 Sum::computing_5 Sum::a1_1 Sum::sreq::valid
Sum::a1 = reg'32 Sum::a1_2 Sum::a1_0
Sum::ea2_0 = mux'1 Sum::computing_5 0'1 Sum::sreq::valid
Sum::ea2 = reg'32 Sum::ea2_0 Sum::tmp10
Sum::sum3_0 = mux'32 Sum::srsp::ready 0'32 Sum::tmp6
Sum::sum3_1 = mux'32 Sum::tmp9 Sum::sum3_0 Sum::tmp6
Sum::sum3_2 = mux'32 Sum::tmp7 Sum::tmp6 Sum::sum3_1
Sum::sum3_3 = mux'1 Sum::srsp::ready 1'1 Sum::mrsp::valid
Sum::sum3_4 = mux'1 Sum::tmp9 Sum::sum3_3 Sum::mrsp::valid
Sum::sum3_5 = mux'1 Sum::tmp7 Sum::mrsp::valid Sum::sum3_4
Sum::sum3_6 = mux'1 Sum::computing_5 Sum::sum3_5 0'1
Sum::sum3 = reg'32 Sum::sum3_6 Sum::sum3_2
Sum::num_reqs4 = reg'8 Sum::reset 0'8
Sum::computing_5_0 = mux'1 Sum::reset 0'1 0'1
Sum::computing_5_1 = mux'1 Sum::tmp9 Sum::srsp::ready 0'1
Sum::computing_5_2 = mux'1 Sum::tmp7 0'1 Sum::computing_5_1
Sum::computing_5_3 = mux'1 Sum::computing_5 Sum::computing_5_2 0'1
Sum::computing_5_4 = mux'1 Sum::reset 1'1 Sum::computing_5_3
Sum::computing_5 = reg'1 Sum::computing_5_4 Sum::computing_5_0
EOF

cat >gold.vcd <<"EOF"
EOF

#include "harness.bash"
