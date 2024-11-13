# @author pnikiel
# @date 15-Sep-2022

from hashlib import new
from typing import Callable
from lxml import etree
from madafaka import Madafaka
from Shelter import DpAttrMode
import argparse
from colorama import Fore, Style
from prettytable import PrettyTable
import pdb

def dpe_assert_and_shout_callable(dp, dpe, expected_value, callable):
    test_value = dp.dpes[dpe].orig_value
    if test_value != expected_value:
        callable(f'{dp}.{dpe}', '', f'Expected value was {expected_value} value is {test_value}')

class OpcUaDplValidator():

    def validate_subscription_exists_and_is_active(self, subscription_name):
        # print(f'{Fore.RED}Subscription existence test not yet there!{Style.RESET_ALL}')
        # TODO
        pass

    def validate_variable_can_be_subscribed_to(self, string_address):
        print(f'{Fore.YELLOW}Subscriptable tests not done yet{Style.RESET_ALL}')
        pass

    def validate_subscription(self, madafaka, subscription_dp, new_issue_callable, connection):
        try:
            subscription_dp = madafaka.query_dps(lambda dp: dp.name == subscription_dp and dp.dpt_as_str == '_OPCUASubscription')[0]
            dpe_assert_and_shout_callable(subscription_dp, 'Config.PublishingEnabled', '1', new_issue_callable)
            dpe_assert_and_shout_callable(subscription_dp, 'Config.MonitoredItems.DataChangeFilter.Trigger', '2', new_issue_callable)
            dpe_assert_and_shout_callable(subscription_dp, 'Config.MonitoredItems.TimestampsToReturn', '1', new_issue_callable)
            dpe_assert_and_shout_callable(subscription_dp, 'Config.SubscriptionType', '1', new_issue_callable)
            dpe_assert_and_shout_callable(subscription_dp, 'State.AssignedOPCUAServer', f'"{connection}"', new_issue_callable)
        except ImportError:
            new_issue_callable(subscription_dp, '', 'Subscription missing (even worse: referred to!)')
        
        

    def validate_subscriptions(self, madafaka, connection_dp, new_issue_callable, connection):
        self.valid_subscriptions = []
        subscriptions_dpe = connection_dp.dpes['Config.Subscriptions'].orig_value.split(', ')
        for subscription in subscriptions_dpe:
            print(f'Looking at subscription {subscription}')
            self.validate_subscription(madafaka, subscription, new_issue_callable, connection)

    def validate(self, madafaka: Madafaka, nodeset_path, new_issue_callable: Callable[[str, str, str], None], connection):
        """madafaka - the interface to the DPLs
           nodeset_path - the .xml of the nodeset
           new_issue_callable - the way to store a new issue
           connection - WinCC OA OPCUA connection name that the check is for"""

        ns_tree = etree.parse(nodeset_path)
        nsmap={'ns':'http://opcfoundation.org/UA/2011/03/UANodeSet.xsd'}

        # get connection dp
        try:
            connection_dp = madafaka.query_dps(lambda dp: dp.name == '_' + connection and dp.dpt_as_str == '_OPCUAServer')[0]
        except IndexError:
            raise Exception(f"Check unsuccessful because the connection dp _{connection} seems missing")

        #self.validate_subscriptions(madafaka, connection_dp, new_issue_callable, connection)

        counter = 0
        for dp in madafaka.dps:
            
            for dpe_name in dp.dpes:
                # try:
                dpe = dp.dpes[dpe_name]
                if dpe.addr_ref is None: # has no addr_ref - just fucking skip it
                    continue
                if dpe.address.opcua_server != connection:
                    continue
                print(f"\rN={counter} DPE: {dp.name}.{dpe_name}", end='                       ')
                #print(f"Analyzing address {dpe.address.opcua_address_str} DPE is {fwelmb_dp.name}.{dpe_name}")
                counter += 1
                opcua_address = dpe.address.opcua_address_str.replace('"', '')
                xpath_expr = f"ns:UAVariable[@NodeId='{opcua_address}']"
                xpath_matches = ns_tree.xpath(xpath_expr, namespaces=nsmap)
                xpath_matches_num = len(xpath_matches)
                if xpath_matches_num != 1:
                    new_issue_callable(f'{dp.name}.{dpe_name}', opcua_address, 'Missing in address space')
                    continue
                xpath_match = xpath_matches[0]
                # so now we now that address is there -- let's do a few more checks.
                # do we have a non - IN spont address but subscription is set?
                if not dpe.address.addr_mode in [DpAttrMode.DPATTR_ADDR_MODE_INPUT_SPONT, DpAttrMode.DPATTR_ADDR_MODE_IO_SPONT]:
                    if dpe.address.opcua_subscription != '':
                        new_issue_callable(f'{dp.name}.{dpe_name}', opcua_address, 'Subscription used with non-spont mode')

                # if that is a spont mode, the subscription must exist in WCCOA TODO
                is_subscription = dpe.address.addr_mode in [DpAttrMode.DPATTR_ADDR_MODE_INPUT_SPONT, DpAttrMode.DPATTR_ADDR_MODE_IO_SPONT] # refactor to the option above
                if is_subscription:
                    self.validate_subscription_exists_and_is_active(dpe.address.opcua_subscription)

                # if that's a spont mode, we must be talking about sth that can be subscribed to TODO
                if is_subscription:
                    self.validate_variable_can_be_subscribed_to(dpe.address)

                # if that's a poll-group, it should be warned ;-)
                is_polling = dpe.address.addr_mode in [DpAttrMode.DPATTR_ADDR_MODE_INPUT_POLL, DpAttrMode.DPATTR_ADDR_MODE_IO_POLL]
                if is_polling:
                    new_issue_callable(f'{dp.name}.{dpe_name}', opcua_address, 'Polling!')

                # now let see if our address does some output ?
                is_output = dpe.address.addr_mode in [
                    DpAttrMode.DPATTR_ADDR_MODE_OUTPUT,
                    DpAttrMode.DPATTR_ADDR_MODE_OUTPUT_SINGLE,
                    DpAttrMode.DPATTR_ADDR_MODE_IO_POLL,
                    DpAttrMode.DPATTR_ADDR_MODE_IO_SPONT,
                    DpAttrMode.DPATTR_ADDR_MODE_IO_SQUERY]
                if is_output:
                    as_access_level = int(xpath_match.attrib.get('AccessLevel', 1)) # 1 is the default, as per the xsd.
                    # uastack/opcua_builtintypes.h:1977:#define OpcUa_AccessLevels_CurrentWrite 0x2
                    # uastack/opcua_builtintypes.h:1980:#define OpcUa_AccessLevels_CurrentReadOrWrite 0x3
                    if as_access_level not in [2, 3]:
                        new_issue_callable(f'{dp.name}.{dpe_name}', opcua_address, 'Output address, but not writable in address space')
                # if subscription, can this item be subscribed to ?
        print()


def main():

    issues_table = PrettyTable()
    issues_table.field_names = ['DPE', 'PA', 'Issue']
    for field in issues_table.field_names:
        issues_table.align[field] = 'l'

    def simple_notification(dpe, address, problem_type):
        issues_table.add_row([dpe, address, problem_type])

    parser = argparse.ArgumentParser()
    parser.add_argument('--dpl_pickle', required=True)
    parser.add_argument('--address_space', required=True)
    parser.add_argument('--connection', required=True)

    args = parser.parse_args()

    madafaka = Madafaka(args.dpl_pickle)
    validator = OpcUaDplValidator()
    validator.validate(madafaka, args.address_space, simple_notification, args.connection)
    print(issues_table)

if __name__ == "__main__":
    main()
