def Pastrynode do
    use Genserver

    def init(:ok) do
        #NodeId of the node
        nodeId = 0
        #Number of nodes in the network
        numNode = 0
        #Number of requests seen by the node
        numReq = 0
        #Number of rows in the routing table
        numRows = 0
        {:ok, {nodeId, numNode, numReq, numRows}}
    end

    def handle_call({:route, msg, key}) do
        #send the message to the key
    end

    def handle_cast({:deliver, msg, key}) do
        #send the message delivered notification
        #might want to send a notification to the pastry API regarding convergence here
    end

    def handle_cast({:forward, msg, key, nextId}) do
        #message forwarded to the node with nodeId as nextId
    end

    def handle_cast({:newLeafs, leafSet}) do
        #node will inform about a new leaf set here
        #might also want to send a message to the pastry API if it is to make application wide changes
    end

    #Set the initial values of the pastry network. All the initial values are provided here.
    #Setting up of the routing table and all will be done after this.
    def setValues(pid, nodeId, numNode, numReq, log4) do
        Genserver.cast(pid, {:setValues, nodeId, numNode, numReq, numRows})
    end

    #Setting up of the initial values.
    #After this the query for the routing table, the leaf nodes and the neighbour nodes can be done.
    def handle_cast(:setValues, sentNodeId, sentNumNode, sentNumReq, sentNumRows) do
        nodeId = sentNodeId
        numNode = sentNumNode
        numReq = sentNumReq
        numRows = sentNumRows
        {:noreply, {nodeId, numNode, numReq, numRows}}
    end

end