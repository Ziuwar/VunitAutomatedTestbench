# Set the vcd filename to load
set vcd_file "lib.e_alertenablequalification_tb.ch_two_undercurrent_alertlatch_tb"
#Get a list if signal change times of the reference signal
set signal "e_alertenablequalification_tb.trigger"

#Subfolder where the vcd file can be found
set vcd_folder ".\\vcd\\"
# Format the loadFile string
append load_file $vcd_folder $vcd_file ".vcd"
#Open new gtkwave tab
gtkwave::loadFile $load_file
#Sets the time frame around the timeslot to be displayed
set time_frame 2000
#Generate the filename and paths for print data/screenshot
set pdf_path ".\\pdf\\"
set pdf_suffix ".pdf"
append pdf_path_one $pdf_path $vcd_file "_1" $pdf_suffix
append pdf_path_two $pdf_path $vcd_file "_2" $pdf_suffix
append pdf_path_three $pdf_path $vcd_file "_3" $pdf_suffix
append pdf_path_four $pdf_path $vcd_file "_4" $pdf_suffix
append pdf_path_five $pdf_path $vcd_file "_5" $pdf_suffix
set png_path ".\\images\\"
set png_suffix ".png"
append png_path_one $png_path $vcd_file "_1" $png_suffix
append png_path_two $png_path $vcd_file "_2" $png_suffix
append png_path_three $png_path $vcd_file "_3" $png_suffix
append png_path_four $png_path $vcd_file "_4" $png_suffix
append png_path_five $png_path $vcd_file "_5" $png_suffix

#Add all signals
#set nfacs [ gtkwave::getNumFacs ]
set all_facs [list]
#for {set i 0} {$i < $nfacs } {incr i} {
#    set facname [ gtkwave::getFacName $i ]
#    lappend all_facs "$facname"
#	puts "$facname"
#}

lappend all_facs "e_alertenablequalification_tb.AlertLatch_TB"
lappend all_facs "e_alertenablequalification_tb.Alert_TB"
lappend all_facs "e_alertenablequalification_tb.CurrentSenseAlertStatesDeb_TB"
lappend all_facs "e_alertenablequalification_tb.DelayPls1_TB"
lappend all_facs "e_alertenablequalification_tb.DelayPls2_TB"
lappend all_facs "e_alertenablequalification_tb.DelayPls3_TB"
lappend all_facs "e_alertenablequalification_tb.DelayPls4_TB"
lappend all_facs "e_alertenablequalification_tb.EN1_TB"
lappend all_facs "e_alertenablequalification_tb.EN2_TB"
lappend all_facs "e_alertenablequalification_tb.EN3_TB"
lappend all_facs "e_alertenablequalification_tb.EN4_TB"
lappend all_facs "e_alertenablequalification_tb.M_Clk_TB"
lappend all_facs "e_alertenablequalification_tb.M_Rst_TB"
lappend all_facs "e_alertenablequalification_tb.MainAlert_TB"
lappend all_facs "e_alertenablequalification_tb.RstTmr1_TB"
lappend all_facs "e_alertenablequalification_tb.RstTmr2_TB"
lappend all_facs "e_alertenablequalification_tb.RstTmr3_TB"
lappend all_facs "e_alertenablequalification_tb.RstTmr4_TB"
lappend all_facs "e_alertenablequalification_tb.clock_go"
lappend all_facs "e_alertenablequalification_tb.trigger"

set num_added [ gtkwave::addSignalsFromList $all_facs ]
puts "Number if signals added: $num_added"

#Get a list if signal change times of the reference signal
set start_time 1
set end_time 30000
set max_signals 10
set sig_count 0
foreach {time value} [gtkwave::signalChangeList $signal -start_time $start_time -end_time $end_time -max $max_signals] {
	if {$sig_count == 0 && $value == 1} {
		puts "Time: $time value: $value"
		set marker_time_one "$time"
		incr sig_count
	} elseif {$sig_count == 1 && $value == 1} {
		puts "Time: $time value: $value"
		set marker_time_two "$time"		
		incr sig_count
	} elseif {$sig_count == 2 && $value == 1} {
		puts "Time: $time value: $value"
		set marker_time_three "$time"		
		incr sig_count
	} elseif {$sig_count == 3 && $value == 1} {
		puts "Time: $time value: $value"
		set marker_time_four "$time"		
		incr sig_count
	} elseif {$sig_count == 4 && $value == 1} {
		puts "Time: $time value: $value"
		set marker_time_five "$time"		
		incr sig_count
	}
}

#Highlight the interesting signal(s)
gtkwave::setTraceHighlightFromNameMatch $signal on

#Screenshot ONE
#View setup - First max then min value
gtkwave::setToEntry [expr $marker_time_one + $time_frame]
gtkwave::setFromEntry [expr $marker_time_one - $time_frame]
#Zoom range to full window
gtkwave::/Time/Zoom/Zoom_Best_Fit

#Set Marker One
gtkwave::setMarker $marker_time_one

#Print data / Screenshot
gtkwave::/File/Print_To_File PDF {Letter (8.5" x 11")} Full $pdf_path_one
gtkwave::/File/Grab_To_File $png_path_one

#Screenshot TWO
#View setup  - First max then min value
gtkwave::setToEntry [expr $marker_time_two + $time_frame]
gtkwave::setFromEntry [expr $marker_time_two - $time_frame]
#Zoom range to full window
gtkwave::/Time/Zoom/Zoom_Best_Fit

#Set Marker Two
gtkwave::setMarker $marker_time_two

#Print data / Screenshot
gtkwave::/File/Print_To_File PDF {Letter (8.5" x 11")} Full $pdf_path_two
gtkwave::/File/Grab_To_File $png_path_two

#Screenshot THREE
#View setup  - First max then min value
gtkwave::setToEntry [expr $marker_time_three + $time_frame]
gtkwave::setFromEntry [expr $marker_time_three - $time_frame]
#Zoom range to full window
gtkwave::/Time/Zoom/Zoom_Best_Fit

#Set Marker Three
gtkwave::setMarker $marker_time_three

#Print data / Screenshot
gtkwave::/File/Print_To_File PDF {Letter (8.5" x 11")} Full $pdf_path_three
gtkwave::/File/Grab_To_File $png_path_three

#Screenshot FOUR
#View setup  - First max then min value
gtkwave::setToEntry [expr $marker_time_four + $time_frame]
gtkwave::setFromEntry [expr $marker_time_four - $time_frame]
#Zoom range to full window
gtkwave::/Time/Zoom/Zoom_Best_Fit

#Set Marker Four
gtkwave::setMarker $marker_time_four

#Print data / Screenshot
gtkwave::/File/Print_To_File PDF {Letter (8.5" x 11")} Full $pdf_path_four
gtkwave::/File/Grab_To_File $png_path_four

#Screenshot FIVE
#View setup  - First max then min value
gtkwave::setToEntry [expr $marker_time_five + $time_frame]
gtkwave::setFromEntry [expr $marker_time_five - $time_frame]
#Zoom range to full window
gtkwave::/Time/Zoom/Zoom_Best_Fit

#Set Marker Vive
gtkwave::setMarker $marker_time_five

#Print data / Screenshot
gtkwave::/File/Print_To_File PDF {Letter (8.5" x 11")} Full $pdf_path_five
gtkwave::/File/Grab_To_File $png_path_five

gtkwave::/File/Close
