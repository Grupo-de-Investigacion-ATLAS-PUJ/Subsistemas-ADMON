// invokedAESUserFunc
/**
  @par Description:
  Cell click action.

  @par Usage: 
  Internal.

  @par Constraints:
	. PVSS version: 3.11 SP1
	. operating system: Windows 7 64bits, Windows 2008 64bits, SLC6 64bits
	. distributed system: yes.
*/

#uses "fwAlarmHandling/fwAlarmScreenGeneric.ctl"

void invokedAESUserFunc( string shapeName, int screenType, int tabType, int row, int column, string value, mapping mTableRow)
{
  fwAlarmScreenGeneric_invokedAESUserFunc(shapeName, screenType, tabType, row, column, value, mTableRow);
}
