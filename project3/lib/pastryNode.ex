def Pastrynode do
    use Genserver
@b 4
 #Generate Node process
    def start(hashid) do
        {:ok,pid} = GenServer.start(__MODULE__,hashid)
        {pid,hashid}
    end

    def init(args) do  
        {:ok,%{:node_id => args}}
    end

    

    def longest_prefix_match(key,hash_id,start_value,longest_prefix_count) do
            if(String.at(key,start_value) == String.at(hash_id,start_value)) do
            longest_prefix_count=longest_prefix_matched(key,hash_id,start_value+1,longest_prefix_count+1)
            end
            longest_prefix_count
        end

    # fetching nearest node for the last case in pastry
    def searchAllForNearestNeighbour(allSet,key,nodeHash,lngth) do
    
    end 


    def findNearestNeighbour(key,length_longest_prefix,c_idx,ncols,row) do
            
    end

    #Get the length of the longest prefix match
    def getLengthLPM(key,hash,start_value,longest_prefix_count) do
        
    end

    #routing table construction
   def constructNodeRouteTable(nodeHash,nodelist,b) do

    end


    def routeTableRows(node_list,rows,cols,r_idx,node_hash,routing_table) do

    end

    def routeTableCols(node_list,rows,cols,r_idx,c_idx,node_hash,substring,routing_table) do

    end

    #Get functions for the routing table column functions for extra flexibility
    def getRoutTableRow(nrows,ncols,list_routing_table,r_idx,c_idx,routing_table) do

    end


    def getRouteTableCol(nrows,ncols,list_routing_table,r_idx,c_idx,routing_table) do

    end

    def searchIdx(list , s_ele) do
        idx=-1
        Enun.each(Enum.with_index(list), fn({ele,i}) -> (
            if (String.equivalent?(ele,s_ele)) do 
                idx=i
            end 
         ) end) 
        idx
    end

    #calculate the lower leaf and upper leaf sets
    def computeLeafUpperAndLower(sorted_hashid_tup, hashid, hashid_idx) do

        ulimit=tuple_size(sorted_hashid_tup)-1
        lrange=(hashid_idx-8)..hashid_idx
        leaf_lower=Enum.reduce (lrange, {} ,fn(idx, acc_tup) -> (
                if(idx >-1){
                    Tuple.append(acc_tup,elem(sorted_hashid_tup,idx))
                }
        )end)
        # for the lower most case where the list will be null other wise.
        if(tuple_size(leaf_lower)==0) do
            Tuple.append(leaf_lower,hashid)
        end
        #DEBUG
        #IO.inspect leaf_lower
        hrange=hashid_idx..(hashid_idx+8)
        leaf_upper=Enum.reduce (hrange, {} ,fn(idx, acc_tup) -> (
                if(idx < ulimit){
                    Tuple.append(acc_tup,elem(sorted_hashid_tup,idx))
                }
        )end) 
        # for the lower most case where the list will be null other wise.
        if(tuple_size(leaf_upper)==0) do
            Tuple.append(leaf_upper,hashid)
        end
        #DEBUG
        #IO.inspect leaf_upper
        #convert to list and return
        leaf_lower=Tuple.to_list(leaf_lower)
        leaf_upper=Tuple.to_list(leaf_upper)
        #return the leaves
        {leaf_lower,leaf_upper}
    end

    def findMatchingSubstrInList(node_list,substring,nodeHash) do

    end

end