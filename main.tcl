
# Leer el TCL Style
# Escribir pruebas para este deserializador

# Convierte una string tipo CTA en un array
#
# PARAMS
# string - cadena a deserializar
#
# RETURN array
proc deserialize { string } {
  # Muestre como serializar el array
  array set result {}
  set key ""
  foreach step $string {
    if { $key == "" } {
      set key $step
    } else {
      set result($key) $step
      set key ""
    }
  }
  return [array get result]
}

namespace eval labelentry {
  array set lastEdit {
    label ""
    input ""
  }
  variable lastEdit

  proc setup { config entry } {
    array set entr [deserialize $entry]
    array set conf [deserialize $config]

    set label [label $conf(frame).label -text [expr { \
      $entr($conf(key)) != "" ? $entr($conf(key)) : "-" }]]
    bind $label <1> "labelentry::'begin'redact %W {[array get conf]} \
      {[array get entr]}"
    pack $label -side left
  }

  proc 'end'redact { {text ""} } {
    variable lastEdit
    if { $lastEdit(input) != "" } {
      destroy $lastEdit(input)
    }
    if { $lastEdit(label) != "" } {
      $lastEdit(label) configure -text $text
      pack $lastEdit(label) -side left
    }
    set lastEdit(input) ""
    set lastEdit(label) ""
  }

  proc update { el key e } {
    global chan
    array set event [deserialize $e]
    set event(value) [$el get]

    chan puts $chan [array get event]
    labelentry::'end'redact ...
  }

  proc 'begin'redact { el config entry } {
    variable lastEdit
    labelentry::'end'redact
    array set entr [deserialize $entry]
    array set conf [deserialize $config]

    set key $conf(key)
    set frame $conf(frame)

    array set event {
      query update
    }
    set event(from) $conf(from)
    set event(module) $conf(module)

    set event(idkey) $conf(idkey)
    set event(key) $key
    set event(id) $entr($conf(idkey))
    set event(entry) $entry

    set lastEdit(label) $el
    set lastEdit(input) [entry $frame.input]
    $lastEdit(input) insert 0 $entr($key)
    bind $lastEdit(input) <FocusOut> "labelentry::'end'redact {$entr($key)}"
    bind $lastEdit(input) <Return> "labelentry::update %W $key {[array get event]}"
    pack forget $el
    pack $lastEdit(input) -fill x -expand true
  }
}

namespace eval extendcombo {

  proc setup { path } {
    bind $path <KeyRelease> +[list show'listbox $path]
  }

  proc do'autocomplete {path key} {
    #
    # autocomplete a string in the ttk::combobox from the list of values
    #
    # Any key string with more than one character and is not entirely
    # lower-case is considered a function key and is thus ignored.
    #
    # path -> path to the combobox
    #
    if {[string length $key] > 1 && [string tolower $key] != $key} {return}
    set text [string map [list {[} {\[} {]} {\]}] [$path get]]
    if {[string equal $text ""]} {return}
    set values [$path cget -values]
    set x [lsearch $values $text*]
    if {$x < 0} {return}
    set index [$path index insert]
    $path set [lindex $values $x]
    $path icursor $index
    $path selection range insert end
  }

  proc show'listbox { path key } {
    ttk::combobox::Post $path
    update idletasks
    focus $path
    do'autocomplete $path $key
  }

}
