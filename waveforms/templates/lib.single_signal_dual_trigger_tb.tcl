# Set the vcd filename to load
set vcd_file "lib.single_signal_dual_trigger_tb"
#Get a list if signal change times of the reference signal
set signal "e_timerqualification_tb.Reset_TB"

#Subfolder where the vcd file can be found
set vcd_folder ".\\vcd\\"
# Format the loadFile string
append load_file $vcd_folder $vcd_file ".vcd"
#Open new gtkwave tab
gtkwave::loadFile $load_file
#Sets the time frame around the timeslot to be displayed
set time_frame 1000
#Generate the filename and paths for print data/screenshot
set pdf_path ".\\pdf\\"
set pdf_suffix ".pdf"
append pdf_path_one $pdf_path $vcd_file "_1" $pdf_suffix
append pdf_path_two $pdf_path $vcd_file "_2" $pdf_suffix
set png_path ".\\images\\"
set png_suffix ".png"
append png_path_one $png_path $vcd_file "_1" $png_suffix
append png_path_two $png_path $vcd_file "_2" $png_suffix

#Add all signals
set nfacs [ gtkwave::getNumFacs ]
set all_facs [list]
for {set i 0} {$i < $nfacs } {incr i} {
    set facname [ gtkwave::getFacName $i ]
    lappend all_facs "$facname"
}
set num_added [ gtkwave::addSignalsFromList $all_facs ]
puts "Number if signals added: $num_added"

#Get a list if signal change times of the reference signal
set start_time 990000
set end_time  1500000
set max_signals 5
set sig_count 0
foreach {time value} [gtkwave::signalChangeList $signal -start_time $start_time -end_time $end_time -max $max_signals] {
	if {$sig_count == 0 && $value == 0} {
		puts "Time: $time value: $value"
		set marker_time_one "$time"
		incr sig_count
	} else {
		if {
			$sig_count == 1 && $value == 1} {
			puts "Time: $time value: $value"
			set marker_time_two "$time"
			incr sig_count
		}
	}
}

#Highlight the interesting signal(s)
gtkwave::setTraceHighlightFromNameMatch $signal on

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

gtkwave::/File/Close
