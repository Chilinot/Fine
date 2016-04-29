require_relative "../lib/semantic/environment.rb"

describe "environment" do
    context "it is empty" do
        let(:env) {Environment.new}
        it "foo is not defined" do
            expect {env["foo"]}.to raise_error(SemanticError)
        end
        it "foo is defined if we define foo" do
            env["foo"] = {:class => :VARIABLE, :type => :INT}
            expect(env["foo"][:type]).to eq :INT
        end
    end
    context "foo and bar is defined" do
        let(:env) do
            e = Environment.new
            e.add "foo", {:class => :VARIABLE, :type => :INT}
            e.add "bar", {:class => :VARIABLE, :type => :CHAR}
            e
        end
        it "foo and bar is defined" do
            expect(env["foo"][:type]).to eq :INT
            expect(env["bar"][:type]).to eq :CHAR
        end
        it "foobar is not defined" do
            expect {env["foobar"]}.to raise_error(SemanticError)
        end
        it "foo can not be redefined in same scope" do
            expect { env["foo"] = {:class => :VARIABLE, :type => :INT} }.to raise_error(SemanticError)
        end
        context "push a new scope" do
            before(:each) { env.push_scope(:VOID, "awesome") }
            it "foo and bar is still defined after we push a new scope" do
                env.push_scope :VOID, "awesome"
                expect(env["foo"][:type]).to eq :INT
                expect(env["bar"][:type]).to eq :CHAR
            end
            it "foo can be added to the new scope" do
                env["foo"] =  {:class => :VARIABLE, :type => :BOOL}
                expect(env["foo"][:type]).to eq :BOOL
            end
            it "foo can not be added if we pop the new scope" do
                env.pop_scope
                expect { env["foo"] = {:class => :VARIABLE, :type => :BOOL}}.to raise_error(SemanticError)
            end
        end
    end
end
