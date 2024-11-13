// Library loaded as first by every CTRL manager
//
// Due to its name staring with "AAA", this is the first library that will
// be loaded by every CTRL manager and hence could contain the #uses statements
// for all the other libs that need to be loaded *before* anything else
//
// Note that having the filename start with "_" or with a digit is not sufficient,
// because of a peculiar sorting algorithm that is applied.

#uses "fwCore/fwCore.ctl"