showcase
========

A repo for various scripts I'd like others to be able to access

`gloss.rb`
----------

This is a script used to assist authors producing lessons for the [Early Indo-European OnLine (EIEOL)](http://www.utexas.edu/cola/centers/lrc/eieol/) series of lessons.  In particular, this script arose from the need for consistency between glosses.

The problem is as follows.  In writing a series of lessons on [Old Russian](http://www.utexas.edu/cola/centers/lrc/eieol/oruol-0-X.html), in Lesson 1 the author may have to gloss the word иже.  On that particular occurrence, she may use the gloss 'who, he who'.  But in Lesson 10, months later, the same word may occur.  The poor lesson author, however, will have forgotten how she originally glossed it and instead write 'who, he who, the one who'.

As it turns out, because of the difference in definitions, the EIEOL processing scripts will count these as *two different words*, even though it's the same word being glossed.  This will show up as repeated entries for иже in the [Master Glossary](http://www.utexas.edu/cola/centers/lrc/eieol/oruol-MG-X.html), which can be quite annoying for a word as frequent as иже.

The script `gloss.rb` seeks to alleviate such problems by helping the series author remind herself of how she glossed words previously.  In particular, `gloss.rb` is a toolkit for use in the Ruby IDE, and it reads all previous lesson texts and loads all the glosses into memory.  The author can then search this hash of headwords for the particular word being glossed, and print out the entry as written previously for pasting into the current gloss.  In this way, she can consistenly write 'who, he who' for иже every time it occurs.

### Special Bonus Feature

Since the vocabulary of [Old Church Slavonic (OCS)](http://www.utexas.edu/cola/centers/lrc/eieol/ocsol-0-X.html) mixes inexorably with that of [Old Russian](http://www.utexas.edu/cola/centers/lrc/eieol/oruol-0-X.html), it seemed advisable to gloss consistently across *both* lesson series.  But the two series used slightly different beta codes, so that the [Old Russian](http://www.utexas.edu/cola/centers/lrc/eieol/oruol-0-X.html) author could not simply cut and paste from [OCS](http://www.utexas.edu/cola/centers/lrc/eieol/ocsol-0-X.html) and use it in [Old Russian](http://www.utexas.edu/cola/centers/lrc/eieol/oruol-0-X.html).  So `gloss.rb` includes an option that will convert between the two beta codes, putting the glosses of both series in a single format that the [Old Russian](http://www.utexas.edu/cola/centers/lrc/eieol/oruol-0-X.html) series author could cut and paste into lessons being written.