
import pickle
import Shelter

class Dpt:
    def __init__(self, name):
        self.name = name

class Madafaka:
    def __init__(self, pickle_fn):
        f_in = open(pickle_fn, 'rb')
        self.dps = pickle.load(f_in)
        # attach DP information ?
        self.dpts = {}
        self.link_dpts()

    def register_dpt(self, name):
        if not name in self.dpts:
            self.dpts[name] = Dpt(name) # change to be non-overlapping

    def link_dpts(self):
        for dp in self.dps:
            self.register_dpt(dp.dpt_as_str)

    def query_dps(self, predicate):
        result = [dp for dp in self.dps if predicate(dp)]
        return result

    def get_all_dpts(self):
        return self.dpts
