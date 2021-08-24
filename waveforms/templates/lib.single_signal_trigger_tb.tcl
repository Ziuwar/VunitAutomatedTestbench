# Set the vcd filename to load
set vcd_file "lib.e_paritycheckerqualification_tb.even_paritiy_max_fail_tb"
#Subfolder where the vcd file can be found
set vcd_folder ".\\vcd\\"
# Format the loadFile string
append load_file $vcd_folder $vcd_file ".vcd"

#Open new gtkwave tab
gtkwave::loadFile $load_file

#Sets the time frame around the timeslot to be displayed
set time_frame 1000
#Get the filename and print data/screenshot
set filename [ gtkwave::getDumpFileName ]
set filename [string trimright $filename ".vcd"]
set filename [string trimleft $filename ".\\vcd\\"]
set pdf_path ".\\pdf\\"
set pdf_suffix ".pdf"
append pdf_path_one $pdf_path $filename "_1" $pdf_suffix
set png_path ".\\images\\"
set png_suffix ".png"
append png_path_one $png_path $filename "_1" $png_suffix

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
set signal "e_paritycheckerqualification_tb.trigger"
set start_time 100
set end_time 3100000
set max_signals 5
set sig_count 0
foreach {time value} [gtkwave::signalChangeList $signal -start_time $start_time -max $max_signals] {
	if {$sig_count == 0 && $value == 1} {
		puts "Time: $time value: $value"
		set marker_time_one "$time"
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

gtkwave::/File/Close
