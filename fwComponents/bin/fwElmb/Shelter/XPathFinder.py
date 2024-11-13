# @author pnikiel

def get_xpath_by_name(tree, node, supplement_prefix=''):
    at_top = node == tree.getroot()
    if at_top:
        return f"/{supplement_prefix}{node.tag}"
    else:
        this = f"{supplement_prefix}{node.tag}[@name='{node.attrib['name']}']"
        return get_xpath_by_name(tree, node.getparent(), supplement_prefix) + '/' + this

