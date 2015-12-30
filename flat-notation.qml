import QtQuick 2.0
import MuseScore 1.0

MuseScore {
  version:  "0.1"
  description: "This plugin will convert all notes to flat notation."
  menuPath: "Notations.Flat notation"

  property variant tpcFlattenTable: {
    '-1': 11,  '0': 12,  '1': 13,  '2': 14,  '3': 15,  '4': 16,  '5': 17,
     '6':  6,  '7':  7,  '8':  8,  '9':  9, '10': 10, '11': 11, '12': 12,
    '13': 13, '14': 14, '15': 15, '16': 16, '17': 17, '18': 18, '19': 19,
    '20':  8, '21':  9, '22': 10, '23': 11, '24': 12, '25': 13, '26': 14,
    '27': 15, '28': 16, '29': 17, '30': 18, '31': 19, '32':  8, '33':  9
  }

  function applyToNotesInSelection(func) {
    var cursor = curScore.newCursor();
    cursor.rewind(1);
    var startStaff;
    var endStaff;
    var endTick;
    var fullScore = false;
    if (!cursor.segment) { // no selection
      fullScore = true;
      startStaff = 0; // start with 1st staff
      endStaff = curScore.nstaves - 1; // and end with last
    } else {
      startStaff = cursor.staffIdx;
      cursor.rewind(2);
      if (cursor.tick == 0) {
        // this happens when the selection includes
        // the last measure of the score.
        // rewind(2) goes behind the last segment (where
        // there's none) and sets tick=0
        endTick = curScore.lastSegment.tick + 1;
      } else {
        endTick = cursor.tick;
      }
      endStaff = cursor.staffIdx;
    }
    console.log(startStaff + " - " + endStaff + " - " + endTick)
    for (var staff = startStaff; staff <= endStaff; staff++) {
      for (var voice = 0; voice < 4; voice++) {
        cursor.rewind(1); // sets voice to 0
        cursor.voice = voice; //voice has to be set after goTo
        cursor.staffIdx = staff;

        if (fullScore) {
           // if no selection, beginning of score
          cursor.rewind(0)
        }

        while (cursor.segment && (fullScore || cursor.tick < endTick)) {
          if (cursor.element && cursor.element.type == Element.CHORD) {
            var graceChords = cursor.element.graceNotes;
            for (var i = 0; i < graceChords.length; i++) {
              // iterate through all grace chords
              var notes = graceChords[i].notes;
              for (var j = 0; j < notes.length; j++)
                func(notes[j]);
            }
            var notes = cursor.element.notes;
            for (var i = 0; i < notes.length; i++) {
              var note = notes[i];
              func(note);
            }
          }
          cursor.next();
        }
      }
    }
  }

  function flattenNote(note) {
    var tpc = tpcFlattenTable[note.tpc.toString()];
    note.tpc1 = tpc;
    note.tpc2 = tpc;
    if(note.accidental != null && note.accidental.accType == Accidental.NATURAL) {
      note.accidental.visible = false;
    }
  }

  onRun: {
    if (typeof curScore === 'undefined') {
      Qt.quit();
    }
    applyToNotesInSelection(flattenNote)
    Qt.quit();
  }
}
