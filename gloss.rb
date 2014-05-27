#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Methods for organizing and searching glosses
# in the Tocharian Online series

# The structure:
#   We want a Glossary to be a hash where
#   (key,value) == (dictionary_form,entry)
#
# The entry, in turn, takes the form of a hash
# with keys:
#   meaning
#   occurrences
#
# Then occurrences will itself be a hash
# with
#   (key,value) == (surface_form,gloss)
#
# The gloss will be a hash with keys
#   part_of_speech
#   grammatical_analysis
#   contextual_gloss

# Functionality:
#  Within the Glossary, we want to be able
#    to import new entries from a new glossed text
#  Within the Glossary, we want to be able
#    to look up an existing entry
#  Within the Glossary, we want to be able
#    to export a glossary from memory to file
#  Within the Glossary, we want to be able
#    to import an existing glossary file to memory
#  Within an Entry, we want to be able
#    to add new occurrences
#      with the conditions:
#        if the dictionary form is new, make a new Entry;
#        if the dictionary form already occurs, only add
#          to existing Entry

# A Glossary object contains a single hash:
# 
#   headwords == {headword1 => entry1, headword2 => entry2, ...}
# 
# where each headword is the dictionary entry
# of a word.  All more specific data for that term
# is contained in the entry.
class Glossary
  # :headwords is a Hash of the form
  #   headwords == {headword1 => entry1, headword2 => entry2}
  
  attr_accessor :headwords
  
  def initialize(existing_glossary=nil, is_structured=false)
    @headwords = {}
    if existing_glossary
      import(existing_glossary, is_structured)
    end
  end
  
  # find(instring, exact) looks in the Glossary keys,
  # i.e. looks at the headwords, to match instring. If
  # exact is false (default), then the headword must
  # simply contain instring.
  def find(instring, exact=false)
    # find a string in the list of headwords
    # if exact==true, specify exact match
    # otherwise just look for strings that
    # contain the query string
    outstr = "\n"
    headstrings  = matchmaker(instring, exact)
    
    if headstrings.length > 0
      headstrings.each do |form|
        outstr += form + "\n"
        outstr += @headwords[form].to_s(1)
      end
    else
      outstr += 'String not found.'
    end
    
    outstr += "\n"
    puts outstr
  end
  
  # paste(instring, exact) is essentially a combination
  # of find() with a pretty-print.  That is, paste()
  # searches for the given string and outputs the dictionary
  # form and meaning in a format that can simply be pasted
  # into an EIEOL glossed text source document.
  def paste(instring, exact=false)
    headstrings = matchmaker(instring, exact)
    
    if headstrings.length > 0
      outstr = "\n"
      for form in headstrings
        outstr += "<"
        outstr += form + "> "
        outstr += @headwords[form].meaning
        outstr += "\n"
      end
      outstr += "\n"
      puts outstr
    else
      puts 'String not found.'
    end
  end
  
  # matchmaker() is a helper routine for find() and paste()
  def matchmaker(instring, exact=false)
    headstrings = []
    if exact
      found_match = @headwords.has_key?(instring)
      if found_match
        headstrings << instring
      end
    else
      @headwords.keys.each do |key|
        if key.include? instring
          headstrings  << key
          found_match = true
        end
      end
    end
    return headstrings
  end

  # import(infilename, is_structured) reads in a file (default
  # name "./glossary.txt") that contains the glossary of a
  # given EIEOL text or set of texts.  If is_structured is false
  # (defaut), then each line of the file is assumed to contain
  # a single glossed entity.  If true, it's assumed that each
  # headword entry is split over multiple lines, with tab-indenting
  # to signify different sections of the entry:
  #
  # headword_a
  #     meaning
  #         surface_form1
  #             part_of_speech1
  #             grammatical_analysis1
  #             contextual_gloss1
  #         surface_form2
  #             part_of_speech2
  #             grammatical_analysis2
  #             contextual_gloss2
  # 
  # headword_b
  #     ...
  #
  def import(infilename="./glossary.txt", is_structured=false)
    # add entries from an already prepared glossary file
    ifile = File.new(infilename, 'r')
    if !is_structured
      while (line = ifile.gets) do
        add_occurrence line
      end
    else
      # if the file has a hierarchical structure, then we
      # need to use regexen to figure out what data goes where
      
      # define headword here so that its value persists
      # over several loops, until specifically redefined
      headword = ''
      while (line = ifile.gets) do
        # this assumes the structure of Glossary::to_s
        if line =~ /^\S+/
          # we found a new headword
          headword = line.strip
          if @headwords.keys.include? headword
            next
          else
            @headwords[headword] = Entry.new
          end
        elsif line =~ /^\t\S+/
          # we found a line containing word meaning
          # add it only if we don't already have a meaning
          if @headwords[headword].meaning == nil
            @headwords[headword].meaning = line.strip
          end
        elsif line =~ /^\t\t\S+/
          # we found a new occurrence (i.e. surface form)
          occurrence               = Occurrence.new
          occurrence.surface       = line.strip
          occurrence.data          = Gloss.new
          
          # the next three lines will contain
          #   part of speech
          #   grammatical analysis (possibly empty if indeclinable)
          #   contextual gloss
          occurrence.data.ptspeech = ifile.gets.strip
          occurrence.data.analysis = ifile.gets.strip
          occurrence.data.gloss    = ifile.gets.strip
          
          if @headwords[headword].occurrences == nil
            @headwords[headword].occurrences = []
          end
          @headwords[headword].occurrences << occurrence
        else
          # if doesn't start with word characters
          # or right number of tabs, move to the next line
          next
        end
      end
    end
    ifile.close
  end
  
  # export(outfilename, is_structured) takes the Glossary
  # as currently in memory and dumps it to a file.  The structure
  # of the output is identical to that outlined for import().
  def export(outfilename="./glossary.txt", is_structured=false)
    # output glossary in memory to file
    ofile = File.open(outfilename, 'w')
    # We just want *some* ordering on the keys
    # so that things that are similar stay close
    sorted_heads = @headwords.keys.sort
    if is_structured
      # formatted with information on different
      # tab-indented lines
      sorted_heads.each do |headword|
        entry  = @headwords[headword]
        oline  = headword + "\n"
        oline += entry.to_s(1)
        ofile.puts oline
      end
    else
      # format specific to LRC processing
      sorted_heads.each do |headword|
        entry     = @headwords[headword]
        dict_form = headword
        meaning   = entry.meaning
        
        entry.occurrences.each do |occurrence|
          surface  = occurrence.surface
          ptspeech = occurrence.data.ptspeech
          analysis = occurrence.data.analysis
          gloss    = occurrence.data.gloss
          
          oline  = surface   + " @"
          oline += ptspeech  + "; "
          oline += analysis  + " <"
          oline += dict_form + "> "
          oline += meaning   + "@ ["
          oline += gloss     + "]"
          
          ofile.puts oline
        end
      end
    end
    
    ofile.close
  end
  
  # handle_line() reads in a line of the form
  #
  #   word1-word2-word3 @pts1; an1 <wrd1> mng1 + pts2; an2 <wrd2> mng2 + pts3; an3 <wrd3> mng3@ [gls] # nt
  #
  # and returns an array of strings
  #
  #   [ "word1 @pts1; an1 <wrd1> mng1@ [gls]",
  #     "word2 @pts2; an2 <wrd2> mng2@ [gls]",
  #     "word3 @pts3; an3 <wrd3> mng3@ [gls]"]
  #
  # That is, it splits combined glosses into the format
  # of a single gloss.
  def handle_line(line)
    # if the line doesn't have the form
    #   something @ something_else @ another_thing
    # then forget it: it's not a glossary entry
    # (allows us to handle files where not all lines
    # have been glossed yet)
    # Also: don't get confused with "@ @"-sequence
    # used to create paragraph breaks; but these should
    # be handled in add_file with the upcoming_gloss variable
    if !(line =~ /@.*@/)
      return nil
    end
  	
    # a line can contain more than one headword
    #   word1-word2-word3 @pts1; an1 <wrd1> mng1 + pts2; an2 <wrd2> mng2 + pts3; an3 <wrd3> mng3@ [gls] # nt
    # so let's split it into separate lines for each word separately
    hash_sections = line.split("#")
    at_sections   = hash_sections[0].split("@")
    surface_form  = at_sections[0].strip
    begin
      context_gloss = at_sections.last.scan(/\[(.*)\]/)[0][0].strip
    rescue
      puts "\nThe following line is missing the contextual gloss:"
      puts "\t" + line
      puts "Skipping this line...\n"
      return nil
    end
    
    if line =~ /\s+\+\s+/
      plus_sections = at_sections[1].split(" +")
      if surface_form =~ /-/
        # if the surface form is hyphenated,
        # split on the hyphens
        forms = surface_form.split("-")
      else
        # if not hyphenated, copy the surface form
        # once for each dictionary form
        forms = []
        plus_sections.length.times do
          forms << surface_form
        end
      end
    else
      plus_sections  = []
      plus_sections << at_sections[1]
      forms          = []
      forms         << surface_form
    end
    lines = []
    for i in 0...plus_sections.length
      newline  = forms[i]               + ' @'
      newline += plus_sections[i].strip + "@ ["
      newline += context_gloss          + "]"
      lines << newline
    end
    return lines
  end
  
  # strip_line() is a helper routine.
  def strip_line(line)
    headword = line.scan(/(?<=<)(.*)(?=>)/)[0][0].strip
    entry    = Entry.new(line)
    return headword, entry
  end
  
  # add_folder(directoryname) takes a directory and adds
  # the contents of each file as entries in a Glossary.
  #
  # NB: there is no error-checking on the file format.
  # The routine *assumes* that each file has glosses
  # in the format specified for EIEOL glossed texts.
  #
  # The file parsing is done by add_file().  See below.
  def add_folder(directoryname)
    # add entries from a directory containing glossed texts
    # skip directories named
    #   drafts
    # and files containing
    #   .DS_Store
    #   intro
    #   .rb
    #   .py
    #   .sh
    #   .doc
    total = 0
    count = 0
    Dir[directoryname + "/*"].each do |file|
      if File.file? file
        total += 1
        if !( file =~ /intro|\.doc|\.rb|\.py|\.pl|\.DS/ )
          puts "Adding glosses from file #{file} ..."
          add_file file
          count += 1
        end
      end
    end
    puts "Successfully added #{count} out of #{total} files."
  end
  
  # add_file(filename) takes in a file specifically formatted
  # as a source file for EIEOL glossed texts.  It searches for
  # sections with glosses, and parses each line assuming the
  # format
  #
  #   surface_form @prt-of-spch; analysis <dict_form> meaning@ [gloss]
  #
  def add_file(filename)
    # add entries from file containing a glossed text
    # Look for "- - -" and after that follow lines with glosses
    # Look for "-----" and after that follows the line to be glossed
    
    # the file should start with a passage to be glossed
    upcoming_glosses = false
    
    ifile = File.open(filename, 'r')
    while (line = ifile.gets) do
      if !upcoming_glosses
        if line =~ /-[ ]-[ ]-/
          upcoming_glosses = true
        elsif line =~ /.+\s+#\s*\d+/
          # if the line contains a trailing number
          # following "#", then save the number
          # This variable is a throwaway, but it's here
          # for later modifications
          # (cf. Reference class below)
          verse = line.scan(/.+\s+#\s*(\d+)/)[0][0].to_i
        end
      elsif upcoming_glosses
        if line =~ /-{4,5}/
          upcoming_glosses = false
        elsif line =~ /^.+\s@/
          add_entry line
        end
      else
        next
      end
    end
    
    ifile.close
  end
  
  # add_entry(line) takes a line, searches in the Glossary
  # for the corresponding headword, and creates a new Entry
  # (meaning, list of occurrences) for that headword.  If
  # nonexistant, it creates a new headword.
  def add_entry(line)
    lines = handle_line(line)
    
    # assuming the line is formatted as
    #   something @ something_else @ another_thing
    # so that it's a glossary entry, then do something
    if lines
      lines.each do |newline|
        headword, entry = strip_line(newline)
        if @headwords.keys.include?(headword)
          @headwords[headword].add_occurrence(newline)
        else
          @headwords[headword] = Entry.new(newline)
        end
      end
    end
  end
  
  # add_occurrence(line) is an interface to
  # Entry::add_occurrence().
  def add_occurrence(line)
    headword, entry = strip_line(line)
    # @headwords[headword] is an Entry, so
    # invoke Entry::add_occurrence()
    if @headwords.has_key? headword
      @headwords[headword].add_occurrence line
    else
      @headwords[headword] = Entry.new(line)
    end
  end
  
  def apply(options={})
    # allow multiple options keys
    if options.has_key? :filter
      # each key, such as ":filter", is allowed to
      # have multiple values (hence multiple actions)
      
      if options[:filter] == "ocs2oru"
        # below are the character series that involve items
        # which differ between OCS and ORu
        #
        # OCS
        # И	H	U+0418	: Cyrillic capital letter I
        # и	h	U+0438	: Cyrillic small letter i
        # Й	H^	U+0419	: Cyrillic capital letter short I
        # й	h^	U+0439	: Cyrillic small letter short i
        # І	I	U+0406	: Cyrillic capital letter byelorussian-ukrainian I
        # і	i	U+0456	: Cyrillic small letter byelorussian-ukrainian i
        # Ь	I'	U+042C	: Cyrillic capital letter soft SIGN
        # ь	i'	U+044C	: Cyrillic small letter soft sign
        # Е	E	U+0415	: Cyrillic capital letter IE
        # є	e	U+0454	: Cyrillic small letter ukrainian ie
        # Ѣ	E'	U+0462	: Cyrillic capital letter YAT
        # ѣ	e'	U+0463	: Cyrillic small letter yat
        # Ѥ	E/	U+0464	: Cyrillic capital letter iotified E
        # ѥ	e/	U+0465	: Cyrillic small letter iotified e
        # Ѧ	E(	U+0466	: Cyrillic capital letter little YUS
        # ѧ	e(	U+0467	: Cyrillic small letter little yus
        # Ѩ	E\	U+0468	: Cyrillic capital letter iotified little YUS
        # ѩ	e\	U+0469	: Cyrillic small letter iotified little yus
        # Ѫ	O(	U+046A	: Cyrillic capital letter big YUS
        # ѫ	o(	U+046B	: Cyrillic small letter big yus
        # Ѭ	O\	U+046C	: Cyrillic capital letter iotified big YUS
        # ѭ	o\	U+046D	: Cyrillic small letter iotified big yus
        #
        # ORu
        # И	I	U+0418	: Cyrillic capital letter I
        # и	i	U+0438	: Cyrillic small letter i
        # Ӏ	I/	U+04C0	: CYRILLIC capital LETTER PALOCHKA
        # ӏ	i/	U+04CF	: CYRILLIC SMALL LETTER PALOCHKA
        # Ь	I'	U+042C	: Cyrillic capital letter soft SIGN
        # ь	i'	U+044C	: Cyrillic small letter soft sign
        # Й	I^	U+0419	: Cyrillic capital letter short I
        # й	i^	U+0439	: Cyrillic small letter short i
        # Е	E	U+0415	: Cyrillic capital letter IE
        # є	e	U+0454	: Cyrillic small letter ukrainian ie
        # Ѣ	E'	U+0462	: Cyrillic capital letter YAT
        # ѣ	e'	U+0463	: Cyrillic small letter yat
        # E	E^	U+0415	: Cyrillic capital letter IE
        # е	e^	U+0435	: Cyrillic small letter ie
        # Ѥ	E/	U+0464	: Cyrillic capital letter iotified E
        # ѥ	e/	U+0465	: Cyrillic small letter iotified e
        # Ѧ	E|	U+0466	: Cyrillic capital letter little YUS  # was E(
        # ѧ	e|	U+0467	: Cyrillic small letter little yus    # was e(
        # Ѩ	E\	U+0468	: Cyrillic capital letter iotified little YUS
        # ѩ	e\	U+0469	: Cyrillic small letter iotified little yus
        # Ѫ	O|	U+046A	: Cyrillic capital letter big YUS     # was O(
        # ѫ	o|	U+046B	: Cyrillic small letter big yus       # was o(
        # Ѭ	O\	U+046C	: Cyrillic capital letter iotified big YUS
        # ѭ	o\	U+046D	: Cyrillic small letter iotified big yus
        #
        @headwords.keys.each do |key|
          # get the key
          old_key = key
          
          # modify the betacode of the key
          new_key = old_key.gsub(/([iI])(?!\')/, '\1/') # change i to i/, unless it's i' (yer)
          new_key.gsub!(/[h]/, 'i')                     # get rid of h, use i
          new_key.gsub!(/[H]/, 'I')                     # get rid of H, use I
          new_key.gsub!(/([eEoO])\(/, '\1|')            # change e( to e|, etc. (nasalized vowels)
          
          if new_key != old_key
            # create a new headword with the new key
            # and copy over the data from the old key
            @headwords[new_key] = @headwords[old_key]
          
            # remove the old key and its data
            # (only do when old_key != new_key, otherwise
            # you lose the entire entry!)
            @headwords.delete(old_key)
          end
          
          # now that we've modified the headword,
          # let's modify the rest of the entry
          @headwords[new_key].apply(options)
        end
      else
        return
      end
    else
      return
    end
  end
  
end



# An Entry object consists of
#   a meaning (String),
#   a list of occurrences (Array of Occurrence objects).
class Entry
  # An Entry consists of
  #   a meaning,
  #   a list of occurrences
  
  attr_accessor :meaning, :occurrences
  
  def initialize(line=nil)
    if line
      @meaning, occurrence = strip_line(line)
      if @occurrences
        @occurrences << occurrence
      else
        @occurrences = []
        @occurrences << occurrence
      end
    else
      @meaning, @occurrences = nil, nil
    end
  end
  
  def strip_line(line)
    meaning = line.scan(/>(.*)@/)[0][0].strip
    occurrence = Occurrence.new(line)
    return meaning, occurrence
  end
  
  def add_occurrence(line)
    meaning, occurrence = strip_line(line)
    if meaning == @meaning
      @occurrences << occurrence
    end
  end

  def to_s(n=0)
    outstr = "\t"*n + @meaning
    @occurrences.each do |occurrence|
      outstr += "\n" + occurrence.to_s(n+1)
    end
    return outstr
  end
  
  def apply(options={})
    @occurrences.each do |occ|
      occ.apply(options)
    end
  end

end



# An Occurrence object consists of
#   a surface form (String),
#   an associated gloss (object of class Gloss).
class Occurrence
  # An Occurrence consists of
  #   a surface form
  #   an associated gloss
  
  attr_accessor :surface, :data

  def initialize(line=nil)
    if line
      @surface, @data = strip_line(line)
    else
      @surface, @data = nil, nil
    end
  end

  def strip_line(line)
    hash_sections = line.split("#")
    at_sections   = hash_sections[0].split('@')
    surface       = at_sections[0].strip
    data          = Gloss.new(line)
    return surface, data
  end
  
  def to_s(n=0)
    outstr  = "\t"*n + @surface + "\n"
    outstr += @data.to_s(n+1)
  end
  
  def apply(options={})
    if options.has_key? :filter
      if options[:filter] == "ocs2oru"
        @surface.gsub!(/([iI])(?!\')/, '\1/')
        @surface.gsub!(/[h]/, 'i')
        @surface.gsub!(/[H]/, 'I')
        @surface.gsub!(/([eEoO])\(/, '\1|')
      else
        return
      end
    else
      return
    end
  end

end



# A Gloss object consists of
#   the part of speech (String),
#   the grammatical analysis (String),
#   the contextual gloss (String).
class Gloss
  # A Gloss consists of
  #   the part of speech
  #   the grammatical analysis
  #   the contextual gloss
  
  attr_accessor :ptspeech, :analysis, :gloss
  
  def initialize(line=nil)
    if line
      @ptspeech, @analysis, @gloss = strip_line(line)
    else
      @ptspeech, @analysis, @gloss = nil, nil, nil
    end
  end

  def strip_line(line)
    # lines look like this:
    # surface_form @ part_of_speech; analysis <dictionary> meaning@ [contextual_gloss] # notes
    # Uh, oh.  Sometimes the analysis has a semi-colon in it!
    
    # split at "#" and get rid of notes
    hash_sections = line.split("#")
    # split on the '@'-signs
    at_sections   = hash_sections[0].split('@')
    # split the middle section on the semicolon...
    # oops, maybe there's more than one... so use
    # the first, and join the rest replacing the
    # semicolon with a comma
    subsections   = at_sections[1].split(';')
    ptspeech      = subsections[0]
    the_rest      = subsections[1..-1].join(',')
    # get everything before '<', and remove 'of' if present
    analysis_str  = the_rest.scan(/.*(?=<)/)[0]
    analysis      = analysis_str ? analysis_str.gsub(/\sof\s*/,'').strip : ''
    # capture what's in the last section between square parentheses
    gloss         = at_sections.last.scan(/\[(.*)\]/)[0][0]
    return ptspeech, analysis, gloss
  end
  
  def to_s(n=0)
    # indent the output with n tab characters
    outstr  = "\t"*n + @ptspeech + "\n"
    outstr += "\t"*n + @analysis + "\n"
    outstr += "\t"*n + @gloss    + "\n"
    return outstr
  end
  
  def apply(options={})
    return
  end

end



# The Reference class is not yet implemented.  The idea
# is for it to hold data so that the user can track down
# where a given surface form occurred, e.g. in verse number
# n of the text in file some_filename.
class Reference
  # A Reference contains the
  #   filename
  #   verse number (i.e. line number of text, not of the file)
  # of a particular Occurrence of a Gloss
  
  attr_accessor :file, :verse
  
  # to be expanded later, for more refined processing...

end
