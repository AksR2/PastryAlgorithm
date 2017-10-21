def PastryAPI do
    use Genserver

    #Collection of some of the pastry API calls that will be made from a node
    def handle_call({:pastryInit, credential, application}) do
    #create the new node and return the new nodeid(in our case the node id is the pid?)
        {:reply}
    end

    def handle_call({:newLeafs, leafset}) do
        #node will send the message here whenever its leaf set changes
        #applicaiton wide changes will be made here
    end

    def initPastry(numNode, numReq) do
        
        #calculate node space and call the init for each pastry node
    end

end