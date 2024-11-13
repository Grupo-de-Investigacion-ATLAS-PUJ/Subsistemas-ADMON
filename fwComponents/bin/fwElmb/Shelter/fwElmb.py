fwElmb_dpts = ['FwElmbAi']

class FwElmbData():
    pass

def init_structure(dp):
    dp.fwElmb = FwElmbData()

def tag_dp_ids(dp):
    '''Takes a DataPoint and splits its name to get the ids'''
    chunks = dp.name.split('/')
    dp.fwElmb.canbus = chunks[1]
    dp.fwElmb.elmb = chunks[2]
    dp.fwElmb.channel_num = int(dp.dpes['channel'].orig_value.replace('"', ''))
    try:
        dp.fwElmb.channel_name = chunks[4]
    except IndexError:
        pass

def initialize(system):
    for dp in [dp for dp in system.dps if dp.dpt_as_str in fwElmb_dpts]:
        init_structure(dp)
        tag_dp_ids(dp)
