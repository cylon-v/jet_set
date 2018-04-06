require 'spec_helper'

RSpec.describe JetSet do
  it 'has a version number' do
    expect(JetSet::VERSION).not_to be nil
  end

  before :each do
    @container = double(:container)
    @component = double(:component)
  end

  describe 'init' do
    before :each do
      @mapping = double(@mapping)
      allow(@component).to receive(:using_lifetime).with(:singleton)
    end

    context 'when container is not passed' do
      it 'works without an error' do
        allow_any_instance_of(Hypo::Container).to receive(:register_instance).and_return(@component)
        allow_any_instance_of(Hypo::Container).to receive(:register).and_return(@component)

        JetSet::init(@mapping)
      end
    end

    it 'registers required components' do
      expect(@container).to receive(:register_instance).with(@mapping, :mapping).and_return(@component)
      expect(@container).to receive(:register).with(JetSet::EntityBuilder, :entity_builder).and_return(@component)
      expect(@container).to receive(:register).with(JetSet::Mapper, :mapper).and_return(@component)
      expect(@container).to receive(:register).with(JetSet::QueryParser, :query_parser).and_return(@component)

      JetSet::init(@mapping, @container)
    end
  end

  describe 'session opening' do
    before :each do
      allow(@container).to receive(:register_instance).and_return(@component)
      allow(@container).to receive(:register).and_return(@component)
      allow(@container).to receive(:register).and_return(@component)
      allow(@container).to receive(:register).and_return(@component)
      allow(@component).to receive(:using_lifetime)

      JetSet::init(@mapping, @container)

      expect(@container).to receive(:register).with(JetSet::Session, :session).and_return(@component)
      expect(@container).to receive(:register).with(JetSet::DependencyGraph, :dependency_graph).and_return(@component)
    end

    describe 'register_session' do
      context 'when scope is passed' do
        it 'registers session and dependency graph components using the scope' do
          expect(@container).to receive(:register_instance).with(:some_scope, :session_scope).and_return(@component)
          expect(@component).to receive(:use_lifetime).with(:scope).and_return(@component).twice
          expect(@component).to receive(:bind_to).with(:some_scope).twice

          JetSet::register_session(:some_scope)
        end

        it 'registers session and dependency graph components using null-scope' do
          expect(@container).to receive(:register_instance).with(nil, :session_scope).and_return(@component)
          expect(@component).to receive(:use_lifetime).with(:transient).and_return(@component).twice

          JetSet::register_session
        end
      end
    end

    describe 'open_session' do
      before :each do
        @connection = double(:connection)
        @session = double(:session)
        allow(@container).to receive(:resolve).with(:session).and_return(@session)
      end

      context 'when scope is passed' do
        it 'registers session and dependency graph components using the scope' do
          expect(@container).to receive(:register_instance).with(@connection, :connection)
          expect(@container).to receive(:register_instance).with(:some_scope, :session_scope).and_return(@component)
          expect(@component).to receive(:use_lifetime).with(:scope).and_return(@component).twice
          expect(@component).to receive(:bind_to).with(:some_scope).twice

          result = JetSet::open_session(@connection, :some_scope)
          expect(result).to eql(@session)
        end

        it 'registers session and dependency graph components using null-scope' do
          expect(@container).to receive(:register_instance).with(@connection, :connection)
          expect(@container).to receive(:register_instance).with(nil, :session_scope).and_return(@component)
          expect(@component).to receive(:use_lifetime).with(:transient).and_return(@component).twice

          result = JetSet::open_session(@connection)
          expect(result).to eql(@session)
        end
      end
    end
  end

  describe 'map' do
    context 'when a block is not passed' do
      it 'raises MapperError with specific message' do
        expect{JetSet::map}.to raise_error(JetSet::MapperError, 'Mapping should be defined as Ruby block.')
      end
    end
  end
end
