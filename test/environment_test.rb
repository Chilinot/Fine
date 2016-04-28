require_relative "../lib/semantic/environment.rb"

describe "environment" do
    context "it is empty" do
        let(:env) {Environment.new}
        it "foo is not defined" do
            expect {env["foo"]}.to raise_error(SemanticError)
        end
        it "foo is defined if we define foo" do
            env["foo"] = {:type => :INT}
            expect(env["foo"]).to eq :INT
        end
    end
    context "foo and bar is defined" do
        let(:env) do
            e = Environment.new
            e.add "foo", {:type => :INT}
            e.add "bar", {:type => :CHAR}
            e
        end
        it "foo and bar is defined" do
            expect(env["foo"]).to eq :INT
            expect(env["bar"]).to eq :CHAR
        end
        it "foobar is not defined" do
            expect {env["foobar"]}.to raise_error(SemanticError)
        end
        it "foo can not be redefined in same scope" do
            expect { env["foo"] = {:type => :BOOL} }.to raise_error(SemanticError)
        end
        context "push a new scope" do
            before(:each) { env.push_scope }
            it "foo and bar is still defined after we push a new scope" do
                env.push_scope
                expect(env["foo"]).to eq :INT
                expect(env["bar"]).to eq :CHAR
            end
            it "foo can be added to the new scope" do
                env["foo"] =  {:type => :BOOL}
                expect(env["foo"]).to eq :BOOL
            end
            it "foo can not be added if we pop the new scope" do
                env.pop_scope
                expect { env["foo"] = {:type => :BOOL}}.to raise_error(SemanticError)
            end
        end
    end
end