defmodule PastryNode do
    use GenServer

 #Generate Node process
    def start(hashid) do
        {:ok,pid} = GenServer.start(__MODULE__,hashid)
        {pid,hashid}
    end

    def init(args) do  
        {:ok,%{:node_id => args}}
    end

    def longest_prefix_match(key,hash_id,start_value,longest_prefix_count) do
        
        longest_prefix_count=cond do 
            (String.at(key,start_value) == String.at(hash_id,start_value)) ->
                longest_prefix_match(key,hash_id,start_value+1,longest_prefix_count+1)
            true ->
                longest_prefix_count
        end

        # if(String.at(key,start_value) == String.at(hash_id,start_value)) do
        #     longest_prefix_count=longest_prefix_match(key,hash_id,start_value+1,longest_prefix_count+1)
        # end
        longest_prefix_count
    end

    def get_routing_table_entry(key, longest_prefix_count, routing_table) do
        numRow = longest_prefix_count
        #orig numCol = Integer.parse(String.at(key, longest_prefix_count))
        numCol = elem(Integer.parse(String.at(key, longest_prefix_count),16),0)
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
        numCol = elem(Integer.parse(String.at(entry, longest_prefix_count),16),0)
        routing_table_updated = cond do
            routing_table[numRow][numCol] == nil ->
                rowMap = cond do
                    routing_table[numRow] == nil ->
                        %{}
                    true ->
                        routing_table[numRow]
                 end
                #IO.inspect "Rowmap #{rowMap}"
                entry_tup={entry,hashid_pid_map[entry]}
                #IO.inspect "entry_tup #{entry_tup}"
                rowMap = Map.put(rowMap, numCol, entry_tup)
                routing_table = Map.put(routing_table, numRow, rowMap)
                routing_table
            true ->
                routing_table
            end
        #IO.inspect "The updated routing table #{inspect routing_table_updated}"
        routing_table_updated
    end

    #routing table construction
    def computeRouteTable(hashid_pid_map,hashid_slist,hashid) do
        
        routing_table=Enum.reduce(hashid_slist, %{}, fn( entry ,acc_routing_table) -> (
            cond do
                (String.equivalent?(entry,hashid) == false) ->
                    longest_prefix_count = longest_prefix_match(entry,hashid,0,0)
                    acc_routing_table=Map.merge(acc_routing_table ,set_routing_table_entry(entry, longest_prefix_count, hashid_pid_map, acc_routing_table))
                    acc_routing_table
                true ->
                    acc_routing_table
            end
        ) end)

        #IO.inspect "The complete routing table : #{routing_table}"
        routing_table
    end

    def hashdval(hashid) do
        elem(Integer.parse(hashid,16),0)
    end

    #can return nil if search ele not present in the list
    def searchIdx(list , s_ele) do

        idx=Enum.find_index(list, fn (ele) -> (
            String.equivalent?(ele,s_ele) == true
        ) end)

        # Enum.each(Enum.with_index(list), fn({ele,i}) -> (
        #     cond do 
        #         (String.equivalent?(ele,s_ele)) -> 
        #             idx=i
        #         true ->
        #             idx
        #     end 
        #  ) end) 
        
        idx

    end

    #calculate the lower leaf and upper leaf sets ascending (lower) , descending (upper)
    def computeLeafUpperAndLower(hashid_pid_map, sorted_hashid_tup, hashid, hashid_idx) do

        ulimit=tuple_size(sorted_hashid_tup)-1
        lrange=(hashid_idx-8)..(hashid_idx-1)
        leaf_lower=Enum.reduce(lrange, {} ,fn(idx, acc_tup) -> (
                acc_tup=cond do 
                    (idx > -1 ) ->
                        entry=elem(sorted_hashid_tup,idx)
                        acc_tup=Tuple.append(acc_tup,{entry,hashid_pid_map[entry]})
                        acc_tup
                    true->
                        acc_tup
                end
                acc_tup
        )end)
        # for the lower most case where the list will be null other wise.
        
        leaf_lower=cond do 
            (tuple_size(leaf_lower)==0) ->
                Tuple.append(leaf_lower,{hashid,hashid_pid_map[hashid]})
            true ->
                leaf_lower
        end
        #DEBUG
        #IO.inspect leaf_lower
        hrange=(hashid_idx+1)..(hashid_idx+8)
        leaf_upper=Enum.reduce(hrange, [] ,fn(idx, acc_list) -> (
                acc_list= cond do 
                    (idx < ulimit) ->
                        # Tuple.append(acc_tup,elem(sorted_hashid_tup,idx))
                        entry=elem(sorted_hashid_tup,idx)
                        entry_tup={entry,hashid_pid_map[entry]}
                        [entry_tup]++acc_list
                    true ->
                        acc_list
                end
                acc_list
        )end) 
        # for the lower most case where the list will be null other wise.
        leaf_upper= cond do 
            (length(leaf_upper)==0) ->
                # Tuple.append(leaf_upper,hashid)
                [{hashid,hashid_pid_map[hashid]}]++leaf_upper
            true ->
                leaf_upper
        end
        #DEBUG
        #IO.inspect leaf_upper
        #convert to list and return
        leaf_lower=Tuple.to_list(leaf_lower)
        # leaf_upper=Tuple.to_list(leaf_upper)
        #return the leaves
        {leaf_lower,leaf_upper}
    end

    #returns absolute differnce
    def diffKeyElement(key, x) do
        k=elem(Integer.parse(key,16),0)
        x=elem(Integer.parse(x,16),0)
        diff=abs(k-x)
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

        #IO.puts "#{inspect self()} #{inspect state}"

        {:noreply,state}
    end

    def handle_cast({:recieveMessage, currentCount, hashId, nodeList}, state) do
        if(currentCount < state[:num_req]) do
            key = Enum.random(nodeList)
            # nodeList = nodeList -- [key]
            pathTillNow = []
           currentCount= cond do 
                (String.equivalent?(key, hashId) == false) ->
                    GenServer.cast(self(), {:route, hashId, key, 0, pathTillNow})
                    currentCount = currentCount + 1
                    currentCount
                
                true ->
                    currentCount
            end
            GenServer.cast(self(), {:recieveMessage, currentCount, hashId, nodeList})
        end
        {:noreply, state}
    end

    def handle_cast({:route, source, destination, hopCount, pathTillNow}, state) do
        
        # IO.inspect "Inside route Source : #{inspect source} , Destination #{inspect destination}"
        # IO.inspect "PathTill Now: #{inspect pathTillNow}"
        cond do 

            String.equivalent?(source, destination) == true ->
                #call daddy (*ah*) delivered
                # IO.puts "Same"
                #  IO.puts "Same Source : #{inspect source} , Destination: #{inspect destination}"
                 GenServer.cast({:global, :Daddy}, {:delivered,hopCount})

            # length(pathTillNow) > 0 ->              
            
            true -> # Routing logic
                    #MAJORBUG this was causing 0 1 hops in case of routing table logic. This is redundant logic though
                #  if(Enum.member?(pathTillNow, source) == true) do (
                #      #call daddy (*ah*) delivered
                #      IO.puts "Path till now"
                #      IO.puts "Path till now Source : #{inspect source} , Destination: #{inspect destination}"
                #      GenServer.cast({:global, :Daddy}, {:delivered,hopCount-1})
                #  ) else (
                    # IO.puts "Inside routing logic"
                    leaf_upper = state[:leaf_upper]
                    leaf_lower = state[:leaf_lower]
                    leaf_list = leaf_lower ++ leaf_upper
                    {lowest_ele, _}= hd(leaf_lower)
                    {highest_ele, _}= hd(leaf_upper)
                    # minDiffNode = nil
                    # minDiff = nil
                    # minPid = nil
                    destinationval=hashdval(destination)
                    lowest_ele=hashdval(lowest_ele)
                    highest_ele=hashdval(highest_ele)
                
                    # IO.puts "Leaf: #{inspect lowest_ele} , #{inspect destinationval} , #{inspect highest_ele}"
                    if (lowest_ele <= destinationval && destinationval <= highest_ele) do
                        #had to substitute this with reduce since binding inside function is lexically scoped in elixir
                        acc_tup={nil,nil,nil}
                        {minDiffNode,minDiff,minPid} =
                            Enum.reduce(leaf_list, acc_tup, fn({x, pId}, {minDiffNode,minDiff,minPid}) -> (
                                currentDiff = diffKeyElement(destination, x)
                                cond do 
                                    (minDiff == nil || currentDiff < minDiff) ->
                                        minDiff = currentDiff
                                        minDiffNode = x
                                        minPid = pId
                                        {minDiffNode, minDiff, minPid}
                                    true ->
                                        {minDiffNode,minDiff,minPid}
                                end
                            )end)
                        # IO.puts "LeafSet :  #{inspect leaf_lower},#{inspect leaf_upper} with minDiff: #{inspect minDiff} and minNode: #{inspect minDiffNode} source #{inspect source} destination #{inspect destination}"
                        # IO.puts "Inside Leaf #{inspect leaf_lower} , #{inspect leaf_upper} #{minDiff} #{minNode}"
                        # IO.puts "Leaf"
                        pathTillNow = [source] ++ pathTillNow
                        GenServer.cast(minPid, {:route, minDiffNode, destination, hopCount + 1, pathTillNow})
                    else
                        # IO.puts "Inside else of leaf"
                        longest_prefix_count = longest_prefix_match(source, destination,0,0)
                        #
                        routing_table = state[:routing_table]
                        {routing_table_entry,entry_pid} = get_routing_table_entry(destination, longest_prefix_count, routing_table)
                        if(routing_table_entry != nil) do
                            # IO.puts "Source #{inspect source} Destination #{destination} inside routing table : #{inspect routing_table} entry: #{inspect routing_table_entry}"
                            # IO.puts("Path till now #{inspect pathTillNow}")
                            pathTillNow = [routing_table_entry] ++ pathTillNow
                            # IO.puts("Path till now #{inspect pathTillNow}")
                            # IO.puts "Routing table"
                            GenServer.cast(entry_pid, {:route, routing_table_entry, destination, hopCount + 1, pathTillNow})
                        else
                            # IO.puts "Inside else of routing"
                            a_d = diffKeyElement(source, destination)
                            route_list=
                            Enum.reduce(routing_table, [] , fn({r, row} , acc_route_list) ->(
                                row_list=
                                Enum.reduce(row, [], fn({c ,{hashid, pid}},acc_row_list) -> (
                                    acc_row_list = [{hashid, pid}] ++ acc_row_list
                                    acc_row_list
                                )end)
                                
                                acc_route_list=row_list ++ acc_route_list
                                acc_route_list
                            )end)

                            combined_list= leaf_list ++ route_list
                            
                            isFound = Enum.reduce(combined_list, false , fn({x,pid},acc_isFound) -> (
                                t_len = longest_prefix_match(x, destination,0,0)
                                acc_isFound= cond do
                                    (t_len >= longest_prefix_count) ->

                                        t_d = diffKeyElement(x, destination)
                                        acc_isFound=cond do
                                            (acc_isFound == false && t_d < a_d) ->
                                                acc_isFound = true
                                                
                                                pathTillNow = [source] ++ pathTillNow
                                                # IO.puts("Inside the combined case")
                                                # IO.puts("combined case Source #{inspect source} Destination #{inspect destination} Path till now #{inspect pathTillNow} next hop #{inspect x}")
                                                # IO.puts "Inside the combined case #{inspect pathTillNow}"
                                                # IO.puts "Combined case"
                                                GenServer.cast(pid, {:route, x, destination, hopCount + 1, pathTillNow})
                                                acc_isFound
                                            
                                            true ->
                                                acc_isFound
                                            end
                                        acc_isFound

                                    true ->
                                        acc_isFound
                                end

                                acc_isFound
                            )end)

                            # IO.puts "end of the third case now what..."

                            #not expecting this to happen at all. 
                            if(isFound == false) do
                                # call daddy
                                # IO.puts "Inside insane case"
                                GenServer.cast({:global, :Daddy}, {:delivered,hopCount})
                            end

                        end
                    end
 
                #  )end
           
            #true ends here
        
        end
        
        {:noreply, state}
    end

end