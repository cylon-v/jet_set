module JetSet
  class Transaction
    def initialize(session)
      @state = session.connection.transaction
    end

    def commit
      @state.commit
    end

    def rollback
      @state.rollback
    end
  end
end