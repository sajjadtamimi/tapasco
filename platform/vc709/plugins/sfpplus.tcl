
proc create_custom_subsystem_network {{args {}}} {

  variable data [tapasco::get_feature "SFPPLUS"]
  variable ports [sfpplus::get_portlist $data]
  # tapasco::get_board_specs
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_NETWORK
  puts "Creating Network Interfaces for Ports: $ports"
  sfpplus::generate_cores $ports

  current_bd_instance /arch
  create_bd_pin -type clk -dir I sfp_clock
  create_bd_pin -type rst -dir I sfp_reset
  create_bd_pin -type rst -dir I sfp_resetn

  variable value [dict values [dict remove $data enabled]]
  foreach port $value {
    sfpplus::generate_port $port
  }
  puts "Network Connection done"
  current_bd_instance /network
}

if {false} {
  proc create_custom_subsystem_si5324 { } {

    #puts $constraints_file {# Main I2C Bus - 100KHz - SUME}
    #puts $constraints_file {set_property IOSTANDARD LVCMOS18 [get_ports IIC_0_scl_io]}
    #puts $constraints_file {set_property SLEW SLOW [get_ports IIC_0_scl_io]}
    #puts $constraints_file {set_property DRIVE 16 [get_ports IIC_0_scl_io]}
    #puts $constraints_file {set_property PULLUP true [get_ports IIC_0_scl_io]}
    #puts $constraints_file {set_property PACKAGE_PIN AK24 [get_ports IIC_0_scl_io]}

    #puts $constraints_file {set_property IOSTANDARD LVCMOS18 [get_ports IIC_0_sda_io]}
    #puts $constraints_file {set_property SLEW SLOW [get_ports IIC_0_sda_io]}
    #puts $constraints_file {set_property DRIVE 16 [get_ports IIC_0_sda_io]}
    #puts $constraints_file {set_property PULLUP true [get_ports IIC_0_sda_io]}
    #puts $constraints_file {set_property PACKAGE_PIN AK25 [get_ports IIC_0_sda_io]}

    #puts $constraints_file {# i2c_reset[0] - i2c_mux reset - high active}
    #puts $constraints_file {# i2c_reset[1] - si5324 reset - high active}
    #puts $constraints_file {set_property SLEW SLOW [get_ports {i2c_reset[*]}]}
    #puts $constraints_file {set_property DRIVE 16 [get_ports {i2c_reset[*]}]}
    #puts $constraints_file {set_property PACKAGE_PIN AM39 [get_ports {i2c_reset[0]}]}
    #puts $constraints_file {set_property IOSTANDARD LVCMOS18 [get_ports {i2c_reset[0]}]}
    #puts $constraints_file {set_property PACKAGE_PIN BA29 [get_ports {i2c_reset[1]}]}
    #puts $constraints_file {set_property IOSTANDARD LVCMOS18 [get_ports {i2c_reset[1]}]}

    #puts $constraints_file {#  I2C 0 / sda / MIO[51]}
    #puts $constraints_file {set_property iostandard "LVCMOS25" [get_ports "iic_sda_io"]}
    #puts $constraints_file {set_property PACKAGE_PIN "AJ18" [get_ports "iic_sda_io"]}
    #puts $constraints_file {set_property slew "slow" [get_ports "iic_sda_io"]}
    #puts $constraints_file {set_property drive "8" [get_ports "iic_sda_io"]}
    #puts $constraints_file {set_property pullup "TRUE" [get_ports "iic_sda_io"]}
    #puts $constraints_file {set_property PIO_DIRECTION "BIDIR" [get_ports "iic_sda_io"]}
    #puts $constraints_file {#  I2C 0 / scl / MIO[50]}
    #puts $constraints_file {set_property iostandard "LVCMOS25" [get_ports "iic_scl_io"]}
    #puts $constraints_file {set_property PACKAGE_PIN "AJ14" [get_ports "iic_scl_io"]}
    #puts $constraints_file {set_property slew "slow" [get_ports "iic_scl_io"]}
    #puts $constraints_file {set_property drive "8" [get_ports "iic_scl_io"]}
    #puts $constraints_file {set_property pullup "TRUE" [get_ports "iic_scl_io"]}
    #puts $constraints_file {#  I2C 0 / reset / i2c_reset[*]}
    #puts $constraints_file {set_property PIO_DIRECTION "BIDIR" [get_ports "iic_scl_io"]}
    #puts $constraints_file {set_property iostandard "LVCMOS18" [get_ports "i2c_reset[0]"]}
    #puts $constraints_file {set_property PACKAGE_PIN "F20" [get_ports "i2c_reset[0]"]}
    #puts $constraints_file {set_property PACKAGE_PIN "W23" [get_ports "i2c_reset[1]"]}
    #puts $constraints_file {set_property IOSTANDARD "LVCMOS25" [get_ports "i2c_reset[1]"]}
    #puts $constraints_file {set_property slew "slow" [get_ports "i2c_reset[*]"]}
    #puts $constraints_file {set_property drive "8" [get_ports "i2c_reset[*]"]}
    #puts $constraints_file {set_property pullup "TRUE" [get_ports "i2c_reset[*]"]}
    #puts $constraints_file {set_property PIO_DIRECTION "OUTPUT" [get_ports "i2c_reset[*]"]}

    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_SI5324
    puts "Setting up the Clock for 10G-SFP Config"

    #set_property CONFIG.FREQ_HZ 156250000 [get_bd_ports /refclk_p]
    #set_property CONFIG.FREQ_HZ 156250000 [get_bd_ports /refclk_n]

    create_bd_port -dir O -from 1 -to 0 i2c_reset

    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 SI5324Prog_0
    set_property -dict [list CONFIG.C_SCL_INERTIAL_DELAY {5} CONFIG.C_SDA_INERTIAL_DELAY {5} CONFIG.C_GPO_WIDTH {2}] [get_bd_cells SI5324Prog_0]

    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC
    connect_bd_intf_net [get_bd_intf_ports /IIC] [get_bd_intf_pins SI5324Prog_0/IIC]
    connect_bd_intf_net [get_bd_intf_pins S_SI5324] [get_bd_intf_pins SI5324Prog_0/S_AXI]
    connect_bd_net [get_bd_pins SI5324Prog_0/s_axi_aclk] [get_bd_pins design_clk]
    connect_bd_net [get_bd_pins SI5324Prog_0/s_axi_aresetn] [get_bd_pins design_peripheral_aresetn]
    connect_bd_net [get_bd_ports /i2c_reset] [get_bd_pins SI5324Prog_0/gpo]
  }
}



namespace eval sfpplus {
  if {[tapasco::get_board_preset] == "ZC706"} {
    variable available_ports 1
    variable rx_ports       {"Y6"}
    variable tx_ports       {"W4"}
    variable disable_pins   {"AA18"}
    variable refclk_pins    {"AC8"}
    variable disable_pins_voltages {"LVCMOS25"}
  }
  if {[tapasco::get_board_preset] == "VC709"} {
    variable available_ports 4
    variable rx_ports       {"AN6" "AM8" "AL6" "AJ6"}
    variable tx_ports       {"AP4" "AN2" "AM4" "AL2"}
    variable disable_pins   {"AB41" "Y42" "AC38" "AC40"}
    variable fault          {"Y38" "AA39" "AA41" "AE38"}
    variable disable_pins_voltages {"LVCMOS18" "LVCMOS18" "LVCMOS18" "LVCMOS18"}

    variable refclk_pins    {"AH8"}

  }

  #zc706
  ##Y5 rxn
  ##Y6 rxp
  ##W4 txp
  ##W3 txn
  ##AA18 tx_disable
  ##LVCMOS25 tx_disable
  ##AC8 refclk_p

  ###vc709
  ##tx*
  #AP4 AP3
  #AN2 AN1
  #AM4 AM3
  #AL2 AL1
  ##rx*
  #AN6 AN5
  #AM8 AM7
  #AL6 AL5
  #AJ6 AJ5
  ##refclk_*
  #AH8 AH7
  ##tx_disable
  #AB41
  #Y42
  #AC38
  #AC40
  ##tx_fault
  #Y38
  #AA39
  #AA41
  #AE38

proc find_ID {input} {
    variable composition
    for {variable o 0} {$o < [llength $composition] -1} {incr o} {
      if {[regexp ".*:$input:.*" [dict get $composition $o vlnv]]} {
        return $o
      }
    }
    return -1
  }

proc countKernels {kernels} {
    variable counter 0

    foreach kernel $kernels {
      variable counter [expr {$counter + [dict get $kernel Count]}]
    }
    return $counter
  }

proc get_portlist {input} {
    variable counter [list]
    variable value [dict values [dict remove $input enabled]]
    foreach kernel $value {
      variable counter [lappend counter [dict get $kernel PORT]]
    }
    return $counter
  }

proc makeInverter {name} {
    variable ret [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 $name]
    set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells $name]
    return $ret
  }

# Start: Validating Configuration
proc validate_sfp_ports {{args {}}} {
    if {[tapasco::is_feature_enabled "SFPPLUS"]} {
      variable available_ports
      variable composition [tapasco::get_composition]
      set f [tapasco::get_feature "SFPPLUS"]
      variable ky [dict keys $f]
      variable used_ports [list]

      puts "Checking SFP-Network for palausability:"
      # Check if Board supports enough SFP-Ports
      if { [llength $ky]-1 > $available_ports} {
        puts "To many SFP-Ports specified (Max: $available_ports)"
        exit
      }

      #Check if Port Config is valid
      for {variable i 0} {$i < [llength $ky]-1} {incr i} {
        variable port [dict get $f [lindex $ky $i]]
        lappend used_ports [dict get $port PORT]
        variable mode [dict get $port mode]
        puts "Port: [dict get $port PORT]"
        puts "  Mode: $mode"
        dict set [lindex [dict get $port kernel] 0] vlnv " "
        switch $mode {
          singular   { validate_singular $port }
          broadcast  { validate_broadcast $port }
          roundrobin { validate_roundrobin $port }
          default {
            puts "Mode $mode not supported"
            exit
          }
        }
        variable unique_ports [lsort -unique $used_ports]
        if { [llength $used_ports] > [llength $unique_ports]} {
          puts "Port-specification not Unique (Ports Specified: [lsort $used_ports])"
          exit
        }
      }
      puts "SFP-Config OK"

    }
    return {}
}

  # validate Port for singular mode
proc validate_singular {config} {
    variable kern [dict get $config kernel]
    variable composition
    if {[llength $kern] == 1} {
      puts "  Kernel:"
      variable x [lindex $kern 0]
      dict set $x "vlnv" " "
      dict with  x {
        puts "    ID: $ID"
        puts "    Count: $Count"
        puts "    Recieve:  $interface_rx"
        puts "    Transmit: $interface_tx"
        variable kernelID [find_ID $ID]
        if { $kernelID != -1 } {
          variable newCount [expr {[dict get $composition $kernelID count] - $Count}]
          set vlnv [dict get $composition $kernelID vlnv]
          if { $newCount <= 0} {
            puts "Not Enough Instances of Kernel $ID"
            exit
          }
          [dict set composition $kernelID count $newCount]
        } else {
          puts "Kernel not found"
          exit
        }
      }
    } else {
      puts "Only one Kernel allowed in Singular mode"
      exit
    }
  }

  # validate Port for broadcast mode
proc validate_broadcast {config} {
    variable composition
    variable kern [dict get $config kernel]
    for {variable c 0} {$c < [llength $kern]} {incr c} {
      puts "  Kernel_$c:"
      variable x [lindex $kern $c]
      dict set $x "vlnv" " "
      dict with  x {
        puts "    ID: $ID"
        puts "    Count: $Count"
        puts "    Recieve:  $interface_rx"
        puts "    Transmit: $interface_tx"
        variable kernelID [find_ID $ID]
        if { $kernelID != -1 } {
          variable newCount [expr {[dict get $composition $kernelID count] - $Count}]
          set vlnv [dict get $composition $kernelID vlnv]
          if { $newCount < 0} {
            puts "Not Enough Instances of Kernel $ID"
            exit
          }
          [dict set composition $kernelID count $newCount]
        } else {
          puts "Kernel not found"
          exit
        }
      }
    }
  }

# validate Port for roundrobin mode
proc validate_roundrobin {config} {
    variable composition
    variable kern [dict get $config kernel]
    for {variable c 0} {$c < [llength $kern]} {incr c} {
      puts "  Kernel_$c:"
      variable x [lindex $kern $c]
      dict set $x "vlnv" " "
      dict with  x {
        puts "    ID: $ID"
        puts "    Count: $Count"
        puts "    Recieve:  $interface_rx"
        puts "    Transmit: $interface_tx"
        variable kernelID [find_ID $ID]
        if { $kernelID != -1 } {
          variable newCount [expr {[dict get $composition $kernelID count] - $Count}]
          set vlnv [dict get $composition $kernelID vlnv]
          puts "VLNV: $vlnv"
          if { $newCount < 0} {
            puts "Not Enough Instances of Kernel $ID"
          [dict set composition $kernelID count $newCount]
          exit
        }
        } else {
          puts "Kernel not found"
          exit
        }
      }
    }
  }
# END: Validating Configuration

# Generate Network Setup
proc generate_cores {ports} {
  variable rx_ports
  variable tx_ports
  variable disable_pins
  variable refclk_pins
  variable disable_pins_voltages

  create_bd_pin -type clk -dir O sfp_clock
  create_bd_pin -type rst -dir O sfp_resetn
  create_bd_pin -type rst -dir O sfp_reset

  create_bd_port -dir I refclk_n
  create_bd_port -dir I refclk_p
  # AXI Interconnect for Configuration
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 AXI_Config
  set_property CONFIG.NUM_SI 1 [get_bd_cells AXI_Config]
  set_property CONFIG.NUM_MI [llength $ports] [get_bd_cells AXI_Config]

  set dclk_wiz [tapasco::ip::create_clk_wiz dclk_wiz]
  set_property -dict [list CONFIG.USE_SAFE_CLOCK_STARTUP {true} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 100 CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false}] $dclk_wiz

  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 "dclk_reset"

  connect_bd_net [get_bd_pins dclk_wiz/clk_out1] [get_bd_pins dclk_reset/slowest_sync_clk]
  connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins dclk_reset/ext_reset_in]
  connect_bd_net [get_bd_pins design_clk] [get_bd_pins $dclk_wiz/clk_in1]
  connect_bd_net [get_bd_pins AXI_Config/M*_ACLK] [get_bd_pins $dclk_wiz/clk_out1]
  connect_bd_net [get_bd_pins AXI_Config/M*_ARESETN] [get_bd_pins dclk_reset/peripheral_aresetn]

  connect_bd_intf_net [get_bd_intf_pins AXI_Config/S00_AXI] [get_bd_intf_pins S_NETWORK]
  connect_bd_net [get_bd_pins AXI_Config/S00_ACLK] [get_bd_pins design_clk]
  connect_bd_net [get_bd_pins AXI_Config/S00_ARESETN] [get_bd_pins design_interconnect_aresetn]
  connect_bd_net [get_bd_pins AXI_Config/ACLK] [get_bd_pins design_clk]
  connect_bd_net [get_bd_pins AXI_Config/ARESETN] [get_bd_pins design_interconnect_aresetn]

  set constraints_fn "[get_property DIRECTORY [current_project]]/sfpplus.xdc"
  set constraints_file [open $constraints_fn w+]
  puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports %s]} [lindex $refclk_pins 0]  refclk_p]

 #-------------------------------------------------------------------------------------
 #set constraints_fn_late "[get_property DIRECTORY [current_project]]/sfpplus_late.xdc"
 #set constraints_file_late [open $constraints_fn_late w+]

 #puts $constraints_file_late {set_false_path -from [get_clocks -filter name=~*sfpmac_*gthe2_i/RXOUTCLK] -to [get_clocks gt_refclk_clk_p]}
 #puts $constraints_file_late {set_false_path -from [get_clocks gt_refclk_clk_p] -to [get_clocks -filter name=~*sfpmac_*gthe2_i/RXOUTCLK]}

 #puts $constraints_file_late {set_false_path -from [get_clocks -filter name=~*sfpmac_*gthe2_i/TXOUTCLK] -to [get_clocks gt_refclk_clk_p]}
 #puts $constraints_file_late {set_false_path -from [get_clocks gt_refclk_clk_p] -to [get_clocks -filter name=~*sfpmac_*gthe2_i/TXOUTCLK]}

 #close $constraints_file_late
 #read_xdc $constraints_fn_late
 #set_property PROCESSING_ORDER LATE [get_files $constraints_fn_late]


  for {set i 0} {$i < [llength $ports]} {incr i} {
    variable port [lindex $ports $i]
    # Global Ports to Physical
    create_bd_port -dir O txp_$port
    create_bd_port -dir O txn_$port
    create_bd_port -dir O tx_disable_$port
    create_bd_port -dir I rxp_$port
    create_bd_port -dir I rxn_$port
    #create_bd_port -dir I signal_detect_$port
    #create_bd_port -dir I tx_fault_$port
    puts $constraints_file [format {# SFP-Port %d} $port]
    puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports %s]} [lindex $rx_ports $port] rxp_$port]
    puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports %s]} [lindex $tx_ports $port] txp_$port]
    puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports %s]} [lindex $disable_pins $port] tx_disable_$port]
    puts $constraints_file [format {set_property IOSTANDARD %s [get_ports %s]} [lindex $disable_pins_voltages $port] tx_disable_$port]
    #puts $constraints_file [format {set_property PACKAGE_PIN %s [get_ports %s]} [lindex $tx_fault_pins $port] tx_fault_$port]
    #puts $constraints_file [format {set_property IOSTANDARD %s [get_ports %s]} [lindex $disable_pins_voltages $port] tx_fault_$port]

    # Local Pins (Network-Hierarchie)
    create_bd_pin -dir O txp_$port
    create_bd_pin -dir O txn_$port
    create_bd_pin -dir O tx_disable_$port
    create_bd_pin -dir I rxp_$port
    create_bd_pin -dir I rxn_$port
    create_bd_pin -dir I signal_detect_$port
    create_bd_pin -dir I tx_fault_$port
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_RX_$port
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_TX_$port
    # Connect Local pins to Global Ports
    connect_bd_net [get_bd_ports /txp_$port] [get_bd_pins txp_$port]
    connect_bd_net [get_bd_ports /txn_$port] [get_bd_pins txn_$port]
    connect_bd_net [get_bd_ports /tx_disable_$port] [get_bd_pins tx_disable_$port]
    connect_bd_net [get_bd_ports /rxp_$port] [get_bd_pins rxp_$port]
    connect_bd_net [get_bd_ports /rxn_$port] [get_bd_pins rxn_$port]
    #connect_bd_net [get_bd_ports /signal_detect_$port] [get_bd_pins signal_detect_$port]
    #connect_bd_net [get_bd_ports /tx_fault_$port] [get_bd_pins tx_fault_$port]
    # Create Hierachie for the Port
    variable group [create_bd_cell -type hier "PORT_$port"]
    current_bd_instance $group
    # Local Pins (Port-Hierarchie)
    create_bd_pin -dir O txp
    create_bd_pin -dir O txn
    create_bd_pin -dir O tx_disable
    create_bd_pin -dir I rxp
    create_bd_pin -dir I rxn
    create_bd_pin -dir I signal_detect
    create_bd_pin -dir I tx_fault
    create_bd_pin -dir I design_clk
    create_bd_pin -dir I design_interconnect_aresetn
    create_bd_pin -dir I design_peripheral_aresetn
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_RX
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_TX
    create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_Config
    # Connect Port Hierachie to Network Hierarchie
    connect_bd_intf_net [get_bd_intf_pins S_AXI_Config] [get_bd_intf_pins /Network/AXI_Config/M[format %02d $i]_AXI]
    connect_bd_net [get_bd_pins txp] [get_bd_pins /Network/txp_$port]
    connect_bd_net [get_bd_pins txn] [get_bd_pins /Network/txn_$port]
    connect_bd_net [get_bd_pins tx_disable] [get_bd_pins /Network/tx_disable_$port]
    connect_bd_net [get_bd_pins rxp] [get_bd_pins /Network/rxp_$port]
    connect_bd_net [get_bd_pins rxn] [get_bd_pins /Network/rxn_$port]
    connect_bd_net [get_bd_pins signal_detect] [get_bd_pins /Network/signal_detect_$port]
    connect_bd_net [get_bd_pins tx_fault] [get_bd_pins /Network/tx_fault_$port]
    connect_bd_net [get_bd_pins $dclk_wiz/clk_out1] [get_bd_pins design_clk]
    connect_bd_net [get_bd_pins /network/dclk_reset/interconnect_aresetn] [get_bd_pins design_interconnect_aresetn]
    connect_bd_net [get_bd_pins /network/dclk_reset/peripheral_aresetn] [get_bd_pins design_peripheral_aresetn]
    connect_bd_intf_net [get_bd_intf_pins AXIS_RX] [get_bd_intf_pins /Network/AXIS_RX_$port]
    connect_bd_intf_net [get_bd_intf_pins AXIS_TX] [get_bd_intf_pins /Network/AXIS_TX_$port]
    # Create the 10G Network Subsystem for the Port
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_10g_ethernet:3.1 Ethernet10G
    if {$i > 0} {
      set_property -dict [list CONFIG.base_kr {BASE-R} CONFIG.SupportLevel {0} CONFIG.autonegotiation {0} CONFIG.fec {0} CONFIG.Statistics_Gathering {0} CONFIG.Statistics_Gathering {false} CONFIG.TransceiverControl {true} CONFIG.DRP {false}] [get_bd_cells Ethernet10G]
      connect_bd_net [get_bd_pins $main_core/qplllock_out]           [get_bd_pins Ethernet10G/qplllock]
      connect_bd_net [get_bd_pins $main_core/qplloutclk_out]         [get_bd_pins Ethernet10G/qplloutclk]
      connect_bd_net [get_bd_pins $main_core/qplloutrefclk_out]      [get_bd_pins Ethernet10G/qplloutrefclk]
      connect_bd_net [get_bd_pins $main_core/reset_counter_done_out] [get_bd_pins Ethernet10G/reset_counter_done]
      connect_bd_net [get_bd_pins $main_core/txusrclk_out]           [get_bd_pins Ethernet10G/txusrclk]
      connect_bd_net [get_bd_pins $main_core/txusrclk2_out]          [get_bd_pins Ethernet10G/txusrclk2]
      connect_bd_net [get_bd_pins $main_core/txuserrdy_out]          [get_bd_pins Ethernet10G/txuserrdy]
      connect_bd_net [get_bd_pins $main_core/coreclk_out]            [get_bd_pins Ethernet10G/coreclk]
      connect_bd_net [get_bd_pins $main_core/gttxreset_out]          [get_bd_pins Ethernet10G/gttxreset]
      connect_bd_net [get_bd_pins $main_core/gtrxreset_out]          [get_bd_pins Ethernet10G/gtrxreset]
      connect_bd_net [get_bd_pins $main_core/gttxreset_out]          [get_bd_pins Ethernet10G/areset_coreclk]
      connect_bd_net [get_bd_pins /Network/design_peripheral_areset] [get_bd_pins Ethernet10G/areset]
    } else {
      set_property -dict [list CONFIG.base_kr {BASE-R} CONFIG.SupportLevel {1} CONFIG.autonegotiation {0} CONFIG.fec {0} CONFIG.Statistics_Gathering {0} CONFIG.Statistics_Gathering {false} CONFIG.TransceiverControl {true} CONFIG.DRP {false}] [get_bd_cells Ethernet10G]
      set main_core [get_bd_cells Ethernet10G]
      connect_bd_net [get_bd_ports /refclk_p] [get_bd_pins Ethernet10G/refclk_p]
      connect_bd_net [get_bd_ports /refclk_n] [get_bd_pins Ethernet10G/refclk_n]
      connect_bd_net [get_bd_pins Ethernet10G/reset] [get_bd_pins /Network/design_peripheral_areset]
      connect_bd_net [get_bd_pins Ethernet10G/coreclk_out] [get_bd_pins /Network/sfp_clock]

      set out_inv [makeInverter "reset_inverter"]
      connect_bd_net [get_bd_pins Ethernet10G/areset_datapathclk_out] [get_bd_pins /Network/sfp_reset]
      connect_bd_net [get_bd_pins Ethernet10G/areset_datapathclk_out] [get_bd_pins $out_inv/Op1]
      connect_bd_net [get_bd_pins /Network/sfp_resetn] [get_bd_pins $out_inv/Res]
    }

    connect_bd_net [get_bd_pins Ethernet10G/tx_axis_aresetn] [get_bd_pins $out_inv/Res]
    connect_bd_net [get_bd_pins Ethernet10G/rx_axis_aresetn] [get_bd_pins $out_inv/Res]
    connect_bd_intf_net [get_bd_intf_pins Ethernet10G/m_axis_rx] [get_bd_intf_pins AXIS_RX]
    connect_bd_intf_net [get_bd_intf_pins Ethernet10G/s_axis_tx] [get_bd_intf_pins AXIS_TX]
    connect_bd_intf_net [get_bd_intf_pins Ethernet10G/s_axi] [get_bd_intf_pins S_AXI_Config]
    connect_bd_net [get_bd_pins Ethernet10G/txp] [get_bd_pins txp]
    connect_bd_net [get_bd_pins Ethernet10G/txn] [get_bd_pins txn]
    connect_bd_net [get_bd_pins Ethernet10G/rxp] [get_bd_pins rxp]
    connect_bd_net [get_bd_pins Ethernet10G/rxn] [get_bd_pins rxn]
    connect_bd_net [get_bd_pins Ethernet10G/dclk] [get_bd_pins design_clk]
    connect_bd_net [get_bd_pins Ethernet10G/s_axi_aclk] [get_bd_pins design_clk]
    connect_bd_net [get_bd_pins Ethernet10G/s_axi_aresetn] [get_bd_pins design_peripheral_aresetn]
    connect_bd_net [get_bd_pins Ethernet10G/tx_fault] [get_bd_pins tx_fault]
    connect_bd_net [get_bd_pins Ethernet10G/tx_disable] [get_bd_pins tx_disable]
    connect_bd_net [get_bd_pins Ethernet10G/signal_detect] [get_bd_pins signal_detect]
    current_bd_instance /Network
  }
  close $constraints_file
  read_xdc $constraints_fn
  set_property PROCESSING_ORDER EARLY [get_files $constraints_fn]
}

# Build A Port Mode Setups
proc generate_port {input} {
  dict with input {
    variable kernelc [countKernels $kernel]
    puts "Creating Port $PORT"
    puts "  with mode -> $mode"
    puts "  with sync -> $sync"
    puts "  with $kernelc PEs"
    foreach k $kernel {
      puts "    [dict get $k Count] of type [dict get $k ID]"
    }

    create_bd_intf_pin -mode Slave  -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_RX_$PORT
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_TX_$PORT
    # Create Hierarchie-Cell
    create_bd_cell -type hier Port_$PORT
    variable ret [current_bd_instance .]
    current_bd_instance Port_$PORT
    # Create Ports for the Hierarchie
    create_bd_pin -dir I design_clk
    create_bd_pin -dir I design_interconnect_aresetn
    create_bd_pin -dir I design_peripheral_aresetn
    create_bd_pin -dir I design_peripheral_areset
    create_bd_pin -dir I sfp_clock
    create_bd_pin -dir I sfp_reset
    create_bd_pin -dir I sfp_resetn
    create_bd_intf_pin -mode Slave  -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_RX
    create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 AXIS_TX
    # Connect Hierarchie to the Upper Layer
    connect_bd_net [get_bd_pins sfp_clock]  [get_bd_pins /arch/sfp_clock]
    connect_bd_net [get_bd_pins sfp_reset]  [get_bd_pins /arch/sfp_reset]
    connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins /arch/sfp_resetn]
    connect_bd_net [get_bd_pins design_clk] [get_bd_pins /arch/design_clk]
    connect_bd_net [get_bd_pins design_peripheral_aresetn]     [get_bd_pins /arch/design_peripheral_aresetn]
    connect_bd_net [get_bd_pins design_peripheral_areset]      [get_bd_pins /arch/design_peripheral_areset]
    connect_bd_net [get_bd_pins design_interconnect_aresetn]   [get_bd_pins /arch/design_interconnect_aresetn]
    connect_bd_intf_net [get_bd_intf_pins /arch/AXIS_TX_$PORT] [get_bd_intf_pins AXIS_TX]
    connect_bd_intf_net [get_bd_intf_pins /arch/AXIS_RX_$PORT] [get_bd_intf_pins AXIS_RX]
    # Create Port infrastructure depending on mode
    switch $mode {
      singular   { generate_singular [lindex $kernel 0] $PORT $sync }
      broadcast  {
        generate_broadcast $kernelc $sync
        connect_PEs $kernel $PORT
      }
      roundrobin {
        generate_roundrobin $kernelc $sync
        connect_PEs $kernel $PORT
      }
    }
    # Rewire clk and rst connections to syncronize the design to the clk of the Ethernet System
    if {$sync} {
      disconnect_bd_net [get_bd_nets -of_objects [get_bd_pins design_clk]]                  [get_bd_pins design_clk]
      disconnect_bd_net [get_bd_nets -of_objects [get_bd_pins design_peripheral_areset]]    [get_bd_pins design_peripheral_areset]
      disconnect_bd_net [get_bd_nets -of_objects [get_bd_pins design_peripheral_aresetn]]   [get_bd_pins design_peripheral_aresetn]
      disconnect_bd_net [get_bd_nets -of_objects [get_bd_pins design_interconnect_aresetn]] [get_bd_pins design_interconnect_aresetn]
      connect_bd_net [get_bd_pins design_clk]                  [get_bd_pins /arch/sfp_clock]
      connect_bd_net [get_bd_pins design_peripheral_aresetn]   [get_bd_pins /arch/sfp_resetn]
      connect_bd_net [get_bd_pins design_peripheral_areset]    [get_bd_pins /arch/sfp_reset]
      connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins /arch/sfp_resetn]
    }
    current_bd_instance $ret
  }
}

# Create A Broadcast-Config
proc generate_broadcast {kernelc sync} {
  # Create Reciever Interconnect
      create_bd_cell -type ip -vlnv xilinx.com:ip:axis_broadcaster:1.1  reciever
      set_property CONFIG.NUM_MI $kernelc [get_bd_cells reciever]
      set_property -dict [list CONFIG.M_TDATA_NUM_BYTES {8} CONFIG.S_TDATA_NUM_BYTES {8}] [get_bd_cells reciever]

      for {variable i 0} {$i < $kernelc} {incr i} {
          set_property CONFIG.M[format "%02d" $i]_TDATA_REMAP tdata[63:0]  [get_bd_cells reciever]
      }


      connect_bd_net [get_bd_pins design_clk] [get_bd_pins reciever/aclk]
      connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins reciever/aresetn]
  # If not Syncronized insert Interconnect to Sync the Clocks
      if {$sync} {
        connect_bd_intf_net [get_bd_intf_pins reciever/S_AXIS] [get_bd_intf_pins AXIS_RX]
      } else {
        create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 reciever_sync
        set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.S00_FIFO_DEPTH {2048} CONFIG.M00_FIFO_DEPTH {2048} CONFIG.S00_FIFO_MODE {1} CONFIG.M00_FIFO_MODE {1} ] [get_bd_cells reciever_sync]
        connect_bd_net [get_bd_pins sfp_clock]  [get_bd_pins reciever_sync/ACLK]
        connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins reciever_sync/ARESETN]
        connect_bd_net [get_bd_pins sfp_clock]  [get_bd_pins reciever_sync/S*_ACLK]
        connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins reciever_sync/S*_ARESETN]
        connect_bd_net [get_bd_pins design_clk] [get_bd_pins reciever_sync/M*_ACLK]
        connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins reciever_sync/M*_ARESETN]

        connect_bd_intf_net [get_bd_intf_pins reciever/S_AXIS] [get_bd_intf_pins reciever_sync/M*_AXIS]
        connect_bd_intf_net [get_bd_intf_pins reciever_sync/S00_AXIS] [get_bd_intf_pins AXIS_RX]
      }

  # Create Transmitter Interconnect
      create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 transmitter
      set_property -dict [list CONFIG.NUM_MI {1} CONFIG.ARB_ON_TLAST {1}] [get_bd_cells transmitter]
      set_property -dict [list CONFIG.M00_FIFO_MODE {1} CONFIG.M00_FIFO_DEPTH {2048}] [get_bd_cells transmitter]
      set_property CONFIG.NUM_SI $kernelc [get_bd_cells transmitter]
      set_property CONFIG.ARB_ALGORITHM 3 [get_bd_cells transmitter]

      for {variable i 0} {$i < $kernelc} {incr i} {
          set_property CONFIG.[format "S%02d" $i]_FIFO_DEPTH 2048 [get_bd_cells transmitter]
          set_property CONFIG.[format "S%02d" $i]_FIFO_MODE 1 [get_bd_cells transmitter]
      }

      connect_bd_intf_net [get_bd_intf_pins transmitter/M*_AXIS] [get_bd_intf_pins AXIS_TX]
      connect_bd_net [get_bd_pins design_clk] [get_bd_pins transmitter/ACLK]
      connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins transmitter/ARESETN]

      connect_bd_net [get_bd_pins sfp_clock] [get_bd_pins transmitter/M*_ACLK]
      connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins transmitter/M*_ARESETN]

      connect_bd_net [get_bd_pins design_clk] [get_bd_pins transmitter/S*_ACLK]
      connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins transmitter/S*_ARESETN]
}

# Create A Roundrobin-Config
proc generate_roundrobin {kernelc sync} {
  # Create Reciever Interconnect
  create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 reciever
  set_property -dict [list CONFIG.NUM_SI {1} CONFIG.S00_FIFO_MODE {1} CONFIG.S00_FIFO_DEPTH {2048}] [get_bd_cells reciever]
  set_property CONFIG.NUM_MI $kernelc [get_bd_cells reciever]

  for {variable i 0} {$i < $kernelc} {incr i} {
      set_property CONFIG.[format "M%02d" $i]_FIFO_DEPTH 2048 [get_bd_cells reciever]
      set_property CONFIG.[format "M%02d" $i]_FIFO_MODE 1 [get_bd_cells reciever]
  }

  connect_bd_net [get_bd_pins sfp_clock] [get_bd_pins reciever/ACLK]
  connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins reciever/ARESETN]
  connect_bd_net [get_bd_pins sfp_clock] [get_bd_pins reciever/S*_ACLK]
  connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins reciever/S*_ARESETN]
  connect_bd_net [get_bd_pins design_clk] [get_bd_pins reciever/M*_ACLK]
  connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins reciever/M*_ARESETN]

  tapasco::ip::create_axis_arbiter "arbiter"
  create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 roundrobin_turnover
  set_property CONFIG.CONST_WIDTH 5 [get_bd_cells roundrobin_turnover]
  set_property CONFIG.CONST_VAL $kernelc [get_bd_cells roundrobin_turnover]

  connect_bd_net [get_bd_pins arbiter/maxClients] [get_bd_pins roundrobin_turnover/dout]
  connect_bd_net [get_bd_pins arbiter/CLK] [get_bd_pins sfp_clock]
  connect_bd_net [get_bd_pins arbiter/RST_N] [get_bd_pins sfp_resetn]
  connect_bd_intf_net [get_bd_intf_pins arbiter/axis_S] [get_bd_intf_pins AXIS_RX]
  connect_bd_intf_net [get_bd_intf_pins arbiter/axis_M] [get_bd_intf_pins reciever/S*_AXIS]

  # Create Transmitter Interconnect
  create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 transmitter
  set_property -dict [list CONFIG.NUM_MI {1} CONFIG.ARB_ON_TLAST {1}] [get_bd_cells transmitter]
  set_property -dict [list CONFIG.M00_FIFO_MODE {1} CONFIG.M00_FIFO_DEPTH {2048}] [get_bd_cells transmitter]
  set_property CONFIG.NUM_SI $kernelc [get_bd_cells transmitter]
  set_property CONFIG.ARB_ALGORITHM 3 [get_bd_cells transmitter]

  for {variable i 0} {$i < $kernelc} {incr i} {
    set_property CONFIG.[format "S%02d" $i]_FIFO_DEPTH 2048 [get_bd_cells transmitter]
    set_property CONFIG.[format "S%02d" $i]_FIFO_MODE 1 [get_bd_cells transmitter]
  }

  connect_bd_intf_net [get_bd_intf_pins transmitter/M*_AXIS] [get_bd_intf_pins AXIS_TX]
  connect_bd_net [get_bd_pins design_clk] [get_bd_pins transmitter/ACLK]
  connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins transmitter/ARESETN]
  connect_bd_net [get_bd_pins sfp_clock] [get_bd_pins transmitter/M*_ACLK]
  connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins transmitter/M*_ARESETN]
  connect_bd_net [get_bd_pins design_clk] [get_bd_pins transmitter/S*_ACLK]
  connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins transmitter/S*_ARESETN]
}

# Create A Solo-Config
proc generate_singular {kernel PORT sync} {
  dict with kernel {
    variable kern [find_ID $ID]
    variable pes [lrange [get_bd_cells /arch/target_ip_[format %02d $kern]_*] 0 $Count-1]
    move_bd_cells [get_bd_cells Port_$PORT] $pes

    if {$sync} {
      puts "Connecting [get_bd_intf_pins AXIS_RX] to [get_bd_intf_pins [lindex $pes 0]/$interface_rx]"
      connect_bd_intf_net [get_bd_intf_pins AXIS_RX] [get_bd_intf_pins [lindex $pes 0]/$interface_rx]
      puts "Connecting [get_bd_intf_pins AXIS_TX] to [get_bd_intf_pins [lindex $pes 0]/$interface_tx]"
      connect_bd_intf_net [get_bd_intf_pins AXIS_TX] [get_bd_intf_pins [lindex $pes 0]/$interface_tx]
    } else {
      create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 reciever_sync
      set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.S00_FIFO_DEPTH {2048} CONFIG.M00_FIFO_DEPTH {2048} CONFIG.S00_FIFO_MODE {1} CONFIG.M00_FIFO_MODE {1} ] [get_bd_cells reciever_sync]
      connect_bd_net [get_bd_pins sfp_clock]  [get_bd_pins reciever_sync/ACLK]
      connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins reciever_sync/ARESETN]
      connect_bd_net [get_bd_pins sfp_clock]  [get_bd_pins reciever_sync/S*_ACLK]
      connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins reciever_sync/S*_ARESETN]
      connect_bd_net [get_bd_pins design_clk] [get_bd_pins reciever_sync/M*_ACLK]
      connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins reciever_sync/M*_ARESETN]
      puts "Connecting [get_bd_intf_pins reciever_sync/M00_AXIS] to [get_bd_intf_pins [lindex $pes 0]/$interface_rx]"
      connect_bd_intf_net [get_bd_intf_pins reciever_sync/M00_AXIS] [get_bd_intf_pins [lindex $pes 0]/$interface_rx]
      connect_bd_intf_net [get_bd_intf_pins reciever_sync/S00_AXIS] [get_bd_intf_pins AXIS_RX]

      create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 transmitter_sync
      set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.S00_FIFO_DEPTH {2048} CONFIG.M00_FIFO_DEPTH {2048} CONFIG.S00_FIFO_MODE {1} CONFIG.M00_FIFO_MODE {1} ] [get_bd_cells transmitter_sync]
      connect_bd_net [get_bd_pins design_clk]  [get_bd_pins transmitter_sync/ACLK]
      connect_bd_net [get_bd_pins design_interconnect_aresetn] [get_bd_pins transmitter_sync/ARESETN]
      connect_bd_net [get_bd_pins design_clk]  [get_bd_pins transmitter_sync/S*_ACLK]
      connect_bd_net [get_bd_pins design_peripheral_aresetn] [get_bd_pins transmitter_sync/S*_ARESETN]
      connect_bd_net [get_bd_pins sfp_clock] [get_bd_pins transmitter_sync/M*_ACLK]
      connect_bd_net [get_bd_pins sfp_resetn] [get_bd_pins transmitter_sync/M*_ARESETN]
      puts "Connecting [get_bd_intf_pins transmitter_sync/S00_AXIS] to [get_bd_intf_pins [lindex $pes 0]/$interface_tx]"
      connect_bd_intf_net [get_bd_intf_pins transmitter_sync/S00_AXIS] [get_bd_intf_pins [lindex $pes 0]/$interface_tx]
      connect_bd_intf_net [get_bd_intf_pins transmitter_sync/M00_AXIS] [get_bd_intf_pins AXIS_TX]
    }
  }
}

# Group PEs and Connect them to transmitter and reciever
proc connect_PEs {kernels PORT} {
  variable counter 0
  foreach kernel $kernels {
    dict with kernel {
      variable kern [find_ID $ID]
      variable pes [lrange [get_bd_cells /arch/target_ip_[format %02d $kern]_*] 0 $Count-1]
      move_bd_cells [get_bd_cells Port_$PORT] $pes
      for {variable i 0} {$i < $Count} {incr i} {
        puts "Connecting [get_bd_intf_pins reciever/M[format %02d $counter]_AXIS] to [get_bd_intf_pins [lindex $pes $i]/$interface_rx]"
        puts "Connecting [get_bd_intf_pins transmitter/S[format %02d $counter]_AXIS] to [get_bd_intf_pins [lindex $pes $i]/$interface_tx]"
        connect_bd_intf_net [get_bd_intf_pins reciever/M[format %02d $counter]_AXIS] [get_bd_intf_pins [lindex $pes $i]/$interface_rx]
        connect_bd_intf_net [get_bd_intf_pins transmitter/S[format %02d $counter]_AXIS] [get_bd_intf_pins [lindex $pes $i]/$interface_tx]
        variable counter [expr {$counter+1}]
      }
    }
  }
}

proc addressmap {{args {}}} {
    if {[tapasco::is_feature_enabled "SFPPLUS"]} {

      set networkIPs [get_bd_cells -of [get_bd_intf_pins -filter {NAME =~ "*sfp_axis_rx*"} uArch/target_ip_*/*]]

      set host_addr_space [get_bd_addr_space "/host/ps7/Data/"]
      set offset 0x0000000000400000

      set addr_space [get_bd_addr_segs "/network/PORT_0/Ethernet10G/s_axi/Reg0"]
      create_bd_addr_seg -range 64K -offset $offset $host_addr_space $addr_space "Network_i2c"
    }
    return {}
  }

}

tapasco::register_plugin "platform::sfpplus::validate_sfp_ports" "pre-arch"
tapasco::register_plugin "platform::sfpplus::addressmap" "post-address-map"
