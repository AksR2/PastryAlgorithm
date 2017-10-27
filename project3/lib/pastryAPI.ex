def PastryAPI do
    use Genserver

    def handle_call({:newLeafs, leafset}) do
        #node will send the message here whenever its leaf set changes
        #applicaiton wide changes will be made here
    end

    def handle_cast({:handleDelivery, hopCount}, state) do
        {_, requestsReceived} = Map.get_and_update(state, :requestsReceived, fn currentVal -> {currentVal, currentVal + 1} end)
        state = Map.merge(state, requestsReceived)
        {_, hopCount} = Map.get_and_update(state, :hopCount, fn currentVal -> {currentVal, currentVal+hopCount} end)
        state = Map.merge(state, hopCount)

        mapReq = state[:numReq] * state[:numNodes]
        if(state[:requestsReceived] >= (mapReq)) do
            hopCountMean = state[:hopCount]/mapReq
            IO.puts "Mean hop count is: #{inspect hopCountMean}"
            Process.exit(self(), :normal)
        end
        {:noreply, state}
    end

    def handle_cast({:updatePastry, numReq, node_map, numNode}, state) do
        {_, node_map} = Map.get_and_update(state,:node_map, fn currentVal -> {currentVal, node_map} end)
        {_, currentNumNodes} = Map.get_and_update(state, :numNode, fn currentVal ->{currentVal, numNode} end)
        {_, hopCount} = Map.get_and_update(state, :hopCount, fn currentVal -> {currentVal, 0} end)
        {_, currentNumReq} = Map.get_and_update(state, :currentNumReq, fn currentVal -> {currentVal, currentNumReq} end)
        {_, requestsReceived} = Map.get_and_update(state, :requestsReceived, fn currentVal -> {currentVal, 0} end)

        state = Map.merge(state, node_map)
        state = Map.merge(state, currentNumNodes)
        state = Map.merge(state, hopCount)
        state = Map.merge(state, currentNumReq)
        state = Map.merge(state, requestsReceived)

        {:noreply, state}
    end

    def startAlgo(numNode, numReq) do
        {:ok, _} = Genserver.start_link(__MODULE__, :ok, name: {:global, :Daddy})
        rangeOfNum = 1..numNode

        # return the idx_hashid map, hashid_dval map and hashid sorted tuple.
        #only generates the node ids and maps doesn't spawn yet.
        {idx_to_hashid_map,hashid_dval_map,sorted_hashid_tup} = genNodeIds(range)
        
        hashid_pid_map = buildNetwork(idx_to_hashid_map,hashid_dval_map,sorted_hashid_tup)

        Genserver.cast(Daddy, {:updatePastry, numReq, hashid_pid_map, numNode})
        
        sendDataNow(numNode, 0, Map.keys(hashid_pid_map), hashid_pid_map)
    end

    def buildNetwork(idx_to_hashid_map,hashid_dval_map,sorted_hashid_tup,numNodes, numReq) do
        hashid_slist= Tuple.to_list(sorted_hashid_tup)
        # Create a pid to hashid map along with leaf sets , routing table and neighbourhoodset. 
        #each character is 4 bit in hex. and 128 bit hash. Thus 128/4 = 32 which is number of digits in the hashid 
        numRows = 32
        #hard coding for b=4. This is 0-F values which is 16. 
        numCols = 16 
        hashid_pid_map=Enum.reduce(hashid_slist, %{}, fn (hashid, acc_hashid_pid_map) -> (
            hashid_idx=searchIdx(hashid_slist,hashid)
            {leafLower,leafUpper} = PastryNode.computeLeafUpperAndLower(sorted_hashid_tup, hashid,hashid_idx)
            route_table=%{}
            route_table = PastryNode.computeRouteTable(sorted_hashid_tup,hashid_slist,hashid,hashid_idx,route_table)
            {pid,hashid}=PastryNode.start(hashid)
            Genserver.cast(pid,{:updateNode,leafUpper,leafLower,route_table,numReq,numRows,numCols})
            Map.put(acc_hashid_pid_map,hashid,pid)
        )end)


    end

    def genNodeIds(range) do

        # generate the hashids for the range 1..nodenum.
        idx_to_hashid_map=Enum.reduce(range, %{}, fn (idx,acc_idx_hashid_map) -> (
            hashid= :crypto.hash(:md5,"#{idx}") |> Base.encode16()
            Map.put(acc_idx_hashid_map,idx, hashid)
        )end)

        hashrange=Map.values(idx_to_hashid_map)
    
        #hashid to decimal value map.
        hashid_dval_map=Enum.reduce(hashrange, %{}, fn (hashid,acc_hashid_dval_map) -> (
            dval=elem(Integer.parse(hashid,16),0)
            Map.put(acc_hashid_dval_map, hashid,dval)
        )end)

        #sorted hashid map for leaf set generation
        sorted_hashid_tup =  Enum.sort(hashrange, fn(x,y) -> (hashid_dval_map[x]<hashid_dval_map[y])end) |> List.to_tuple

        {idx_to_hashid_map,hashid_dval_map,sorted_hashid_tup}
    end


    def sendDataNow(numNode, currentCount, nodeList, hashIdMap) do
        Enum.each(nodeList, fn(x) -> (
            pId = hashIdMap[x]
            Genserver.cast(pId,{:recieveMessage, pId, 0, x, nodeList})
        ) end)
    end

end