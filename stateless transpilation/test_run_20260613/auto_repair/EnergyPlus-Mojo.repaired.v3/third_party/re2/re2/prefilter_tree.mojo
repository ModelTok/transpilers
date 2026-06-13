from memory import Pointer, new, delete
from prefilter import Prefilter
from .sparse_array import SparseArray
from util.logging import LOG, DCHECK
from util.strutil import StringPrintf
from builtin import List, Dict, String, Int, Bool, Set

alias ExtraDebug = False

struct PrefilterTree:
    # Private types
    alias IntMap = SparseArray[Int]
    alias StdIntMap = Dict[Int, Int]
    alias NodeMap = Dict[String, Pointer[Prefilter]]
    
    struct Entry:
        var propagate_up_at_count: Int
        var parents: Pointer[StdIntMap]
        var regexps: List[Int]
        
        def __init__(inout self):
            self.propagate_up_at_count = 0
            self.parents = Pointer[StdIntMap].null()
            self.regexps = List[Int]()
    
    var entries_: List[Entry]
    var unfiltered_: List[Int]
    var prefilter_vec_: List[Pointer[Prefilter]]
    var atom_index_to_id_: List[Int]
    var compiled_: Bool
    var min_atom_len_: Int
    
    def __init__(inout self):
        self.compiled_ = False
        self.min_atom_len_ = 3
    
    def __init__(inout self, min_atom_len: Int):
        self.compiled_ = False
        self.min_atom_len_ = min_atom_len
    
    def __del__(inout self):
        for i in range(len(self.prefilter_vec_)):
            delete(self.prefilter_vec_[i])
        for i in range(len(self.entries_)):
            delete(self.entries_[i].parents)
    
    def Add(inout self, prefilter: Pointer[Prefilter]):
        if self.compiled_:
            LOG(DFATAL) << "Add called after Compile."
            return
        if prefilter != Pointer[Prefilter].null() and not self.KeepNode(prefilter):
            delete(prefilter)
            prefilter = Pointer[Prefilter].null()
        self.prefilter_vec_.append(prefilter)
    
    def Compile(inout self, atom_vec: inout List[String]):
        if self.compiled_:
            LOG(DFATAL) << "Compile called already."
            return
        if len(self.prefilter_vec_) == 0:
            return
        self.compiled_ = True
        var nodes = NodeMap()
        self.AssignUniqueIds(Pointer[NodeMap](address_of(nodes)), atom_vec)
        for i in range(len(self.entries_)):
            var parents = self.entries_[i].parents
            if (*parents).size() > 8:
                var have_other_guard = True
                for it in (*parents).keys():
                    have_other_guard = have_other_guard and (self.entries_[it].propagate_up_at_count > 1)
                if have_other_guard:
                    for it in (*parents).keys():
                        self.entries_[it].propagate_up_at_count -= 1
                    (*parents).clear()
        if ExtraDebug:
            self.PrintDebugInfo(Pointer[NodeMap](address_of(nodes)))
    
    def RegexpsGivenStrings(self, matched_atoms: List[Int], regexps: inout List[Int]) const:
        regexps.clear()
        if not self.compiled_:
            if len(self.prefilter_vec_) == 0:
                return
            LOG(ERROR) << "RegexpsGivenStrings called before Compile."
            for i in range(len(self.prefilter_vec_)):
                regexps.append(i)
        else:
            var regexps_map = IntMap(len(self.prefilter_vec_))
            var matched_atom_ids = List[Int]()
            for j in range(len(matched_atoms)):
                matched_atom_ids.append(self.atom_index_to_id_[matched_atoms[j]])
            self.PropagateMatch(matched_atom_ids, Pointer[IntMap](address_of(regexps_map)))
            for it in regexps_map:
                regexps.append(it.index())
            regexps.extend(self.unfiltered_)
        regexps.sort()
    
    def PrintPrefilter(self, regexpid: Int):
        LOG(ERROR) << self.DebugNodeString(self.prefilter_vec_[regexpid])
    
    # Private helper methods
    def KeepNode(self, node: Pointer[Prefilter]) -> Bool:
        if node == Pointer[Prefilter].null():
            return False
        var op = (*node).op()
        if op == Prefilter.ALL or op == Prefilter.NONE:
            return False
        if op == Prefilter.ATOM:
            return len((*node).atom()) >= static_cast[Int](self.min_atom_len_)
        if op == Prefilter.AND:
            var j = 0
            var subs = (*node).subs()
            for i in range(len(subs)):
                if self.KeepNode(subs[i]):
                    subs[j] = subs[i]
                    j += 1
                else:
                    delete(subs[i])
            subs.resize(j)
            return j > 0
        if op == Prefilter.OR:
            for i in range(len((*node).subs())):
                if not self.KeepNode((*node).subs()[i]):
                    return False
            return True
        LOG(DFATAL) << "Unexpected op in KeepNode: " << op
        return False
    
    def AssignUniqueIds(inout self, nodes: Pointer[NodeMap], atom_vec: inout List[String]):
        atom_vec.clear()
        var v = List[Pointer[Prefilter]]()
        for i in range(len(self.prefilter_vec_)):
            var f = self.prefilter_vec_[i]
            if f == Pointer[Prefilter].null():
                self.unfiltered_.append(i)
            v.append(f)
        for i in range(len(v)):
            var f = v[i]
            if f == Pointer[Prefilter].null():
                continue
            var op = (*f).op()
            if op == Prefilter.AND or op == Prefilter.OR:
                var subs = (*f).subs()
                for j in range(len(subs)):
                    v.append(subs[j])
        var unique_id = 0
        for i in range(len(v)-1, -1, -1):
            var node = v[i]
            if node == Pointer[Prefilter].null():
                continue
            (*node).set_unique_id(-1)
            var canonical = self.CanonicalNode(nodes, node)
            if canonical == Pointer[Prefilter].null():
                (*nodes)[self.NodeString(node)] = node
                var op = (*node).op()
                if op == Prefilter.ATOM:
                    atom_vec.append((*node).atom())
                    self.atom_index_to_id_.append(unique_id)
                (*node).set_unique_id(unique_id)
                unique_id += 1
            else:
                (*node).set_unique_id((*canonical).unique_id())
        self.entries_.resize(len((*nodes)))
        for i in range(len(v)-1, -1, -1):
            var prefilter = v[i]
            if prefilter == Pointer[Prefilter].null():
                continue
            if self.CanonicalNode(nodes, prefilter) != prefilter:
                continue
            var entry = Pointer[Entry](address_of(self.entries_[(*prefilter).unique_id()]))
            (*entry).parents = Pointer[StdIntMap](new StdIntMap())
        for i in range(len(v)-1, -1, -1):
            var prefilter = v[i]
            if prefilter == Pointer[Prefilter].null():
                continue
            if self.CanonicalNode(nodes, prefilter) != prefilter:
                continue
            var entry = Pointer[Entry](address_of(self.entries_[(*prefilter).unique_id()]))
            var op = (*prefilter).op()
            if op == Prefilter.ATOM:
                (*entry).propagate_up_at_count = 1
            elif op == Prefilter.OR or op == Prefilter.AND:
                var uniq_child = Set[Int]()
                for j in range(len((*prefilter).subs())):
                    var child = (*prefilter).subs()[j]
                    var canonical = self.CanonicalNode(nodes, child)
                    if canonical == Pointer[Prefilter].null():
                        LOG(DFATAL) << "Null canonical node"
                        return
                    var child_id = (*canonical).unique_id()
                    uniq_child.insert(child_id)
                    var child_entry = Pointer[Entry](address_of(self.entries_[child_id]))
                    if not (*(*child_entry).parents).contains((*prefilter).unique_id()):
                        (*(*child_entry).parents)[(*prefilter).unique_id()] = 1
                (*entry).propagate_up_at_count = len(uniq_child) if op == Prefilter.AND else 1
            else:
                LOG(DFATAL) << "Unexpected op: " << op
                return
        for i in range(len(self.prefilter_vec_)):
            if self.prefilter_vec_[i] == Pointer[Prefilter].null():
                continue
            var id = (*self.CanonicalNode(nodes, self.prefilter_vec_[i])).unique_id()
            DCHECK(id >= 0)
            var entry = Pointer[Entry](address_of(self.entries_[id]))
            (*entry).regexps.append(i)
    
    def PropagateMatch(self, atom_ids: List[Int], regexps: inout IntMap) const:
        var count = IntMap(len(self.entries_))
        var work = IntMap(len(self.entries_))
        for i in range(len(atom_ids)):
            work.set(atom_ids[i], 1)
        for it in work:
            var entry_idx = it.index()
            var entry = self.entries_[entry_idx]
            for i in range(len(entry.regexps)):
                regexps.set(entry.regexps[i], 1)
            var c: Int
            for it2 in (*entry.parents).keys():
                var j = it2
                var parent = self.entries_[j]
                if parent.propagate_up_at_count > 1:
                    if count.has_index(j):
                        c = count.get_existing(j) + 1
                        count.set_existing(j, c)
                    else:
                        c = 1
                        count.set_new(j, c)
                    if c < parent.propagate_up_at_count:
                        continue
                work.set(j, 1)
    
    def CanonicalNode(self, nodes: Pointer[NodeMap], node: Pointer[Prefilter]) -> Pointer[Prefilter]:
        var node_string = self.NodeString(node)
        if (*nodes).contains(node_string):
            return (*nodes)[node_string]
        return Pointer[Prefilter].null()
    
    def NodeString(self, node: Pointer[Prefilter]) -> String:
        var s = StringPrintf("%d", (*node).op()) + ":"
        if (*node).op() == Prefilter.ATOM:
            s += (*node).atom()
        else:
            var subs = (*node).subs()
            for i in range(len(subs)):
                if i > 0:
                    s += ','
                s += StringPrintf("%d", subs[i].unique_id())
        return s
    
    def DebugNodeString(self, node: Pointer[Prefilter]) -> String:
        var node_string = String("")
        if (*node).op() == Prefilter.ATOM:
            DCHECK(not (*node).atom().empty())
            node_string += (*node).atom()
        else:
            node_string += "AND" if (*node).op() == Prefilter.AND else "OR"
            node_string += "("
            for i in range(len((*node).subs())):
                if i > 0:
                    node_string += ','
                node_string += StringPrintf("%d", (*node).subs()[i].unique_id())
                node_string += ":"
                node_string += self.DebugNodeString((*node).subs()[i])
            node_string += ")"
        return node_string
    
    def PrintDebugInfo(self, nodes: Pointer[NodeMap]):
        LOG(ERROR) << "#Unique Atoms: " << len(self.atom_index_to_id_)
        LOG(ERROR) << "#Unique Nodes: " << len(self.entries_)
        for i in range(len(self.entries_)):
            var parents = self.entries_[i].parents
            var regexps = self.entries_[i].regexps
            LOG(ERROR) << "EntryId: " << i << " N: " << (*parents).size() << " R: " << len(regexps)
            for key in (*parents).keys():
                LOG(ERROR) << key
        LOG(ERROR) << "Map:"
        for key in (*nodes).keys():
            var node = (*nodes)[key]
            LOG(ERROR) << "NodeId: " << (*node).unique_id() << " Str: " << key

# The PrefilterTree class is part of the re2 namespace; in Mojo we omit the namespace.