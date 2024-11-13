import pickle
import logging
import argparse
from time import sleep
from Shelter import AsciiLoader

def main():
    parser = argparse.ArgumentParser(description='Loads DPL files and stores the collection of DPs as a Python pickle')
    parser.add_argument('--input', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--CANOPEN_addr_dpl', required=False)

    intrinsic_variables_piotr = [".portError", ".portErrorDescription", ".bootupCounter", ".nmtPartialBackwardsCompat", ".Emergency.lastErrorCode", ".Emergency.lastErrorByte3", 
                                ".Emergency.lastErrorByte4", ".Emergency.lastErrorByte5", ".Emergency.lastErrorByte6", ".Emergency.lastErrorByte7", ".state"]
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)

    #Clean dpl export
    with open(args.input, 'r', encoding='iso8859-1') as file:
        lines = file.readlines()
        
    with open(args.input, 'w', encoding='iso8859-1') as file:
        prev_line_blank = False
        for line in lines:
            if line.strip() == '':
                if not prev_line_blank:
                    file.write(line)
                prev_line_blank = True
            else:
                file.write(line)
                prev_line_blank = False
    
    sleep(10)

    loader = AsciiLoader(args.input)
    dps = loader.loadDataPoints()
    loader.loadAliasesAndComments(dps)
    loader.loadValues(dps)
    loader.loadAddresses(dps)

    addr_applied = False
    for element in intrinsic_variables_piotr:
        if element in loader.og_addr:
            #addr_applied = True
            break
    #loader.og_addr - check new addresses
    if args.CANOPEN_addr_dpl is not None and addr_applied is False:
        with open(args.CANOPEN_addr_dpl, 'w') as f:
            f.write(loader.og_addr)
    elif args.CANOPEN_addr_dpl is not None and addr_applied is True:
        print("Creating OG_CANOPEN_addr_dpl is not allowed since _full.dpl allready contains new addresses!")
    else:
        pass

    fo = open(args.output, 'wb')
    pickle.dump(dps, fo)

    print('No exception so far, so the pickle was created. Use "dps" object in it.')

if __name__ == "__main__":
    main()
