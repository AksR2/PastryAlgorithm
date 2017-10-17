def Pastrynode do
    use Genserver

    def init(:ok) do
        #add stuff
    end

    def handle_cast({:route, msg, key}) do
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

end