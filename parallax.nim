import psg


type
  TimedNote = object
    note: Natural
    duration: Natural


const parallax = [
  TimedNote(note: octave(C_NOTE, 2), duration: 500),
  TimedNote(note: octave(F_SHARP_NOTE, 2), duration: 250),
  TimedNote(note: octave(A_SHARP_NOTE, 2), duration: 550),
  TimedNote(note: octave(F_SHARP_NOTE, 2), duration: 500),
  TimedNote(note: octave(C_NOTE, 2), duration: 500),
  TimedNote(note: octave(F_SHARP_NOTE, 2), duration: 250),
  TimedNote(note: octave(A_SHARP_NOTE, 2), duration: 550),
  TimedNote(note: octave(F_SHARP_NOTE, 2), duration: 500),
  TimedNote(note: octave(C_NOTE, 2), duration: 250),
  TimedNote(note: octave(F_SHARP_NOTE, 2), duration: 250),

  {TimedNote(C_NOTE, 2), 500),
  {TimedNote(F_SHARP_NOTE, 2), 250),
  {TimedNote(A_SHARP_NOTE, 2), 550),
  {TimedNote(F_SHARP_NOTE, 2), 500),
  {TimedNote(C_NOTE, 2), 500),
  {TimedNote(F_SHARP_NOTE, 2), 250),
  {TimedNote(A_SHARP_NOTE, 2), 550),
  {TimedNote(F_SHARP_NOTE, 2), 500),
  {TimedNote(C_NOTE, 2), 250),
  {TimedNote(C_SHARP_NOTE, 2), 250),

  {TimedNote(D_NOTE, 2), 500),
  {TimedNote(F_SHARP_NOTE, 2), 250),
  {TimedNote(A_SHARP_NOTE, 2), 550),
  {TimedNote(F_SHARP_NOTE, 2), 500),
  {TimedNote(D_NOTE, 2), 500),
  {TimedNote(F_SHARP_NOTE, 2), 250),
  {TimedNote(A_SHARP_NOTE, 2), 550),
  {TimedNote(F_SHARP_NOTE, 2), 500),
  {TimedNote(D_NOTE, 2), 250),
  {TimedNote(F_SHARP_NOTE, 2), 250),

  {TimedNote(D_NOTE, 2), 500),
  {TimedNote(F_SHARP_NOTE, 2), 250),
  {TimedNote(A_SHARP_NOTE, 2), 550),
  {TimedNote(F_SHARP_NOTE, 2), 500),
  {TimedNote(D_NOTE, 2), 500),
  {TimedNote(F_SHARP_NOTE, 2), 250),
  {TimedNote(A_SHARP_NOTE, 2), 250),
  {TimedNote(D_NOTE, 2), 250),
  {TimedNote(D_SHARP_NOTE, 2), 250),
  {TimedNote(D_NOTE, 2), 250),
  {TimedNote(C_NOTE, 2), 250),
  {TimedNote(D_NOTE, 2), 250),
);
]