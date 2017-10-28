defmodule PastryAPI do
    use GenServer

    def init(:ok) do
        {:ok,%{}}
    end

    def handle_cast({:delivered, hopCount}, state) do
         curhop=hopCount
        {_, requestsReceived} = Map.get_and_update(state, :requestsReceived, fn currentVal -> {currentVal, currentVal + 1} end)
        state = Map.merge(state, requestsReceived)
        {_, hopCount} = Map.get_and_update(state, :hopCount, fn currentVal -> {currentVal, currentVal+hopCount} end)
        state = Map.merge(state, hopCount)

        #IO.inspect "numReq : #{inspect state[:numReq]}"
        #IO.inspect "numNodes : #{inspect state[:numNode]}"

        mapReq = state[:numReq] * state[:numNode]
        if(state[:requestsReceived] >= (mapReq-1)) do
            hopCountMean = state[:hopCount]/mapReq
            IO.puts "Mean hop count is: #{inspect hopCountMean}"
            Process.exit(self(), :normal)
        end

        # hopCountMean = state[:hopCount]/mapReq
        # IO.puts "Current hop count: #{inspect curhop}"
        # IO.puts "Inter Mean hop count is: #{inspect hopCountMean}"
        # IO.puts "Inter req: #{inspect state[:requestsReceived]}"
        # IO.puts "Delivered Finally!!!"
        {:noreply, state}
    end

    def handle_cast({:updatePastry, numReq, node_map, numNode}, state) do
        # IO.puts "inside update pastry"
        #IO.inspect "node map : #{inspect node_map}"
        {_, node_map} = Map.get_and_update(state,:node_map, fn currentVal -> {currentVal, node_map} end)
        # IO.puts "done node map"
        # IO.inspect node_map
        {_, currentNumNodes} = Map.get_and_update(state, :numNode, fn currentVal ->{currentVal, numNode} end)
        {_, hopCount} = Map.get_and_update(state, :hopCount, fn currentVal -> {currentVal, 0} end)
        {_, numReq} = Map.get_and_update(state, :numReq, fn currentVal -> {currentVal, numReq} end)
        {_, requestsReceived} = Map.get_and_update(state, :requestsReceived, fn currentVal -> {currentVal, 0} end)

        #IO.inspect " Reqrcvd: #{inspect requestsReceived}"
        state = Map.merge(state, node_map)
        state = Map.merge(state, currentNumNodes)
        state = Map.merge(state, hopCount)
        state = Map.merge(state, numReq)
        state = Map.merge(state, requestsReceived)
        {:noreply, state}
    end

    def startAlgo(numNode, numReq) do
        {:ok, _} = GenServer.start_link(__MODULE__, :ok, name: {:global, :Daddy})
        rangeOfNum = 1..numNode

        # return the idx_hashid map, hashid_dval map and hashid sorted tuple.
        #only generates the node ids and maps doesn't spawn yet. 
        {sorted_hashid_tup, hashrange} = genNodeIds(rangeOfNum)
        hashid_slist=Tuple.to_list(sorted_hashid_tup)
        #intialize the hashid pid map and then build the network using that
       # IO.inspect "sorted hashid list :#{inspect hashid_slist}"
        hashid_pid_map=getPIDforHashid(hashid_slist)
        # IO.puts "done hashid pid map "
        buildNetwork(hashid_pid_map,sorted_hashid_tup, hashid_slist,numReq)
        # IO.puts "done build network"
        GenServer.cast({:global, :Daddy}, {:updatePastry, numReq, hashid_pid_map, numNode})
        # IO.puts "done update pastry"
        sendDataNow(Map.keys(hashid_pid_map), hashid_pid_map)
        # testsend(sorted_hashid_tup, hashid_pid_map)
    end

    def getPIDforHashid(hashid_slist) do
        hashid_pid_map=Enum.reduce(hashid_slist, %{}, fn(hashid, acc_hashid_pid_map ) -> (
            {pid,hashid}=PastryNode.start(hashid)
            acc_hashid_pid_map = Map.put(acc_hashid_pid_map,hashid,pid)
            acc_hashid_pid_map
        )end)

        #IO.inspect "hashid map : #{inspect hashid_pid_map}"
        hashid_pid_map
    end


    def buildNetwork(hashid_pid_map,sorted_hashid_tup, hashrange, numReq) do
        hashid_slist= Tuple.to_list(sorted_hashid_tup)
        # Create a pid to hashid map along with leaf sets , routing table and neighbourhoodset. 
        #each character is 4 bit in hex. and 128 bit hash. Thus 128/4 = 32 which is number of digits in the hashid 
        numRows = 32
        #hard coding for b=4. This is 0-F values which is 16. 
        numCols = 16 

        #TODO: make creation of static distributed and test.. This is still serial intiailization...
        Enum.each(hashid_slist, fn (hashid) -> (
            join(hashid_slist, hashid, hashid_pid_map, sorted_hashid_tup,hashrange, numReq, numRows, numCols)
        )end)
    end

    def join(hashid_slist, hashid, hashid_pid_map, sorted_hashid_tup,hashrange, numReq, numRows, numCols) do
            hashid_idx=PastryNode.searchIdx(hashid_slist,hashid)
            {leafLower,leafUpper} = PastryNode.computeLeafUpperAndLower(hashid_pid_map,sorted_hashid_tup, hashid,hashid_idx)
            route_table = PastryNode.computeRouteTable(hashid_pid_map, hashrange, hashid)  
            # IO.puts "Route table for hashID #{inspect hashid} , Table : Row1 #{inspect route_table[0]} "
            # IO.puts "Row2 #{inspect route_table[1]}"
            GenServer.cast(hashid_pid_map[hashid],{:updateNode,leafUpper,leafLower,route_table,numReq,numRows,numCols})
    end

    def genNodeIds(range) do

        # generate the hashids for the range 1..nodenum.
        idx_to_hashid_map=Enum.reduce(range, %{}, fn (idx,acc_idx_hashid_map) -> (
            hashid= :crypto.hash(:md5,"#{idx}") |> Base.encode16()
            acc_idx_hashid_map=Map.put(acc_idx_hashid_map,idx, hashid)
            acc_idx_hashid_map
        )end)

        hashrange=Map.values(idx_to_hashid_map)
    
        #hashid to decimal value map.
        hashid_dval_map=Enum.reduce(hashrange, %{}, fn (hashid,acc_hashid_dval_map) -> (
            dval=elem(Integer.parse(hashid,16),0)
            hashid_dval_map=Map.put(acc_hashid_dval_map, hashid,dval)
            hashid_dval_map
        )end)

        #sorted hashid map for leaf set generation.
        sorted_hashid_tup =  Enum.sort(hashrange, fn(x,y) -> (hashid_dval_map[x]<hashid_dval_map[y])end) |> List.to_tuple

        {sorted_hashid_tup,hashrange}
    end


    def sendDataNow(nodeList, hashIdMap) do
        #IO.inspect nodeList
        Enum.each(nodeList, fn(x) -> (
            pId = hashIdMap[x]
            GenServer.cast(pId,{:recieveMessage, 0, x, nodeList})
        ) end)
        # IO.puts "Ending send data"
    end

    # def testsend(sorted_hashid_tup,hashid_pid_map) do 
    #     source=elem(sorted_hashid_tup,8)
    #     destination=elem(sorted_hashid_tup,93)
    #     pathTillNow=[]
    #      GenServer.cast(hashid_pid_map[source], {:route, source, destination, 0, pathTillNow})
    # end

end