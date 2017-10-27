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

    def get_routing_table_entry(key, longest_prefix_count, routing_table) do
        numRow = longest_prefix_count
        numCol = Integer.parse(String.at(key, longest_prefix_count+1))
        result = cond do
            routing_table[numRow][numCol] != nil ->
                routing_table[numRow][numCol]
            true ->
                {nil,nil}
        end
        result
    end

    def set_routing_table_entry(entry, longest_prefix_count, hashid_pid_map, routing_table) do 
        numRow = longest_prefix_count
        numCol = elem(Integer.parse(String.at(entry, longest_prefix_count+1),16),0)
        routing_table_updated = cond do
            routing_table[numRow][numCol] == nil ->
                rowMap = routing_table[numRow]
                entry_tup={entry,hashid_pid_map[entry]}
                rowMap = Map.put(rowMap, numCol, entry_tup)
                routing_table = Map.put(routing_table, numRow, rowMap)
            true ->
                routing_table
            end
        IO.inspect "The updated routing table #{routing_table_updated}"
        routing_table_updated
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
    def computeRouteTable(hashid_pid_map,sorted_hashid_tup,hashid_slist,hashid,hashid_idx,routing_table) do
        
        routing_table=Enum.reduce(hashid_slist, %{}, fn( entry ,acc_routing_table) -> (
            if(String.equivalent?(entry,hashid) == false) do
                 longest_prefix_count = longest_prefix_match(key,hashid,0,0)
                 acc_routing_table=Map.merge (acc_routing_table ,set_routing_table_entry(entry, longest_prefix_count, hashid_pid_map, acc_routing_table))
            end
        ) end)

        IO.inspect "The complete routing table : #{routing_table}"
        routing_table
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

    #calculate the lower leaf and upper leaf sets ascending (lower) , descending (upper)
    def computeLeafUpperAndLower(hashid_pid_map, sorted_hashid_tup, hashid, hashid_idx) do

        ulimit=tuple_size(sorted_hashid_tup)-1
        lrange=(hashid_idx-8)..hashid_idx
        leaf_lower=Enum.reduce (lrange, {} ,fn(idx, acc_tup) -> (
                if(idx > -1){
                    entry=elem(sorted_hashid_tup,idx)
                    Tuple.append(acc_tup,{entry,hashid_pid_map[entry]})
                }
                acc_tup
        )end)
        # for the lower most case where the list will be null other wise.
        if(tuple_size(leaf_lower)==0) do
            Tuple.append(leaf_lower,{hashid,hashid_pid_map[hashid]})
        end
        #DEBUG
        #IO.inspect leaf_lower
        hrange=hashid_idx..(hashid_idx+8)
        leaf_upper=Enum.reduce (hrange, [] ,fn(idx, acc_list) -> (
                if(idx < ulimit){
                    # Tuple.append(acc_tup,elem(sorted_hashid_tup,idx))
                    entry=elem(sorted_hashid_tup,idx)
                    entry_tup={entry,hashid_pid_map[entry]}
                    [entry_tup]++acc_list
                }
                acc_list
        )end) 
        # for the lower most case where the list will be null other wise.
        if(length(leaf_upper)==0) do
            # Tuple.append(leaf_upper,hashid)
            [{hashid,hashid_pid_map[entry]}]++leaf_upper
        end
        #DEBUG
        #IO.inspect leaf_upper
        #convert to list and return
        leaf_lower=Tuple.to_list(leaf_lower)
        # leaf_upper=Tuple.to_list(leaf_upper)
        #return the leaves
        {leaf_lower,leaf_upper}
    end

    def diffKeyElement(key, x) do
        k=elem(Integer.parse(key,16),0)
        x=elem(Integer.parse(x,16),0)
        diff=k-x
        diff
    end

    def handle_cast({:updateNode,leaf_upper,leaf_lower,routing_table,num_req,num_rows,num_cols},state) do
        {_,leaf_upper}=Map.get_and_update(state,:leaf_upper, fn current_value -> {current_value,leaf_upper} end)
        {_,leaf_lower}=Map.get_and_update(state,:leaf_lower, fn current_value -> {current_value,leaf_lower} end)
        {_,routing_table}=Map.get_and_update(state,:routing_table, fn current_value -> {current_value,routing_table} end)
        {_,num_req}=Map.get_and_update(state,:num_req, fn current_value -> {current_value,num_req} end)
        # {_,hop_count}=Map.get_and_update(state,:hop_count, fn current_value -> {current_value,0} end)
        {_,num_rows}=Map.get_and_update(state,:num_rows, fn current_value -> {current_value,num_rows} end)
        {_,num_cols}=Map.get_and_update(state,:num_cols, fn current_value -> {current_value,num_cols} end)


        state=Map.merge(state,leaf_upper)
        state=Map.merge(state,leaf_lower)
        state=Map.merge(state, routing_table)
        state=Map.merge(state, num_req)
        # state=Map.merge(state, hop_count)
        state=Map.merge(state, num_rows)
        state=Map.merge(state, num_cols)

        IO.puts "#{inspect self()} #{inspect state}"

        {:noreply,state}
    end

    def handle_cast({:recieveMessage, currentCount, hashId, nodeList}, state) do
        if(currentCount < state[:num_req]) do
            key = Enum.random(nodeList)
            nodeList = nodeList -- [key]
            pathTillNow = []
            if(String.equivalent?(key, hashId) == false) do
                Genserver.cast(self(), {:route, hashId, key, 0, pathTillNow})
                currentCount = currentCount + 1
            end
            Genserver.cast(self(), {:recieveMessage, pId, currentCount, hashId, nodeList})
        end
        {:noreply, state}
    end

    def handle_cast({:route, source, destination, hopCount, pathTillNow}, state) do
        if(length(pathTillNow) > 0) do
            if(Enum.member?(pathTillNow, source) == true) do
                #call daddy (*ah*) delivered
                {:noreply, state}
            end
        end
        if(String.equivalent?(source, destination) == true) do
            #call daddy (*ah*) delivered
            {:noreply, state}
        end
        leaf_upper = state[:leaf_upper]
        leaf_lower = state[:leaf_lower]
        leaf_list = leaf_lower ++ leaf_upper
        lowest_ele = hd(leaf_lower)
        highest_ele = hd(leaf_upper)
        minDiffNode = nil
        minDiff = nil
        minPid = nil
        if (lowest_ele <= source && source <= highest_ele) do
            Enum.each(leaf_list, fn({x, pId}) -> (
                currentDiff = diffKeyElement(key, x)
                if(minDiff == nil || currentDiff < minDiff) do
                    minDiff = currentDiff
                    minDiffNode = x
                    minPid = pId
                end
            )end)
            pathTillNow = [source] ++ pathTillNow
            Genserver.cast(minPid, {:route, minDiffNode, destination, hopCount + 1, pathTillNow})
        else
            longest_prefix_count = longest_prefix_match(source, destination)
            routing_table = state[:routing_table]
            {routing_table_entry,entry_pid} = get_routing_table_entry(destination, longest_prefix_count, routing_table)
            if(routing_table_entry != nil) do
                pathTillNow = [routing_table_entry] ++ pathTillNow
                Genserver.cast(entry_pid, {:route, routing_table_entry, destination, hopCount + 1, pathTillNow})
            else
                a_d = diffKeyElement(source, destination)
                Enum.each(routing_table, fn({r, row}) ->(
                    Enum.each(row, fn(c, {hashid, pid}) -> (
                        leaf_list = [{hashid, pid}] ++ leaf_list
                    )end)
                )end)
                isFound = false
                Enum.each(leaf_list, fn({x,pid}) -> (
                    t_len = longest_prefix_match(x, destination)
                    if(t_len >= longest_prefix_count) do
                        t_d = diffKeyElement(x, destination)
                        if(isFound == false && t_d < a_d) do
                            isFound = true
                            pathTillNow = [source] ++ pathTillNow
                            Genserver.cast(pid, {:route, x, destination, hopCount + 1, pathTillNow})
                        end
                    end
                )end)

                #not expecting this to happen at all.
                if(isFound == false) do
                    # call daddy
                end

            end
        end

        {:noreply, state}
    end

end