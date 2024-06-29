require "time"
require "html_builder"
require "common"
require "api"

struct Team
  getter :rank, :name, :scores

  def initialize(@rank : String, @name : String, @scores : Array(String?))
  end
end

class Scoreboard
  getter :categories, :teams

  def initialize(@categories : Array(String), @teams : Array(Team))
  end

  def self.parse(str, kind)
    lines = str.strip.split("\n")
    categories = lines[0].strip.split("|")[3...-1].map { |s| s.strip.lchop(kind) }
    teams = lines[2..].select { |v| v.includes?('|') }.map do |line|
      es = line.strip.delete('*').split("|")
      rank = es[1]
      name = es[2]
      scores = es[-categories.size - 1...-1].map { |v| v.strip }.map { |v| v.empty? ? nil : v }
      Team.new(rank, name, scores)
    end
    Scoreboard.new(categories, teams)
  end

  def output(filename, title)
    html = HTML.build do
      doctype
      html() do
        head do
          title { text title }
          tag("meta", charset: "UTF-8") { }
          link(href: "../style.css", rel: "stylesheet")
        end
      end
      html "\n"
      body do
        h1 { text title }
        html "\n"
        table {
          thead {
            tr {
              td { text "rank" }
              td(class: "name") { text "name" }
              @categories.each do |cat|
                td(class: "category") { text cat }
              end
            }
          }
          html "\n"
          tbody {
            @teams.each do |team|
              tr {
                td(class: "rank") { text team.rank }
                td(class: "name") { text team.name }
                team.scores.each do |score|
                  td(class: "score") { text(score ? score : "") }
                end
              }
            end
          }
        }
      end
    end
    File.open(filename, "w") do |f|
      f.print(html)
    end
  end
end

def main
  now = Time.local
  datetime = sprintf("%02d%02d%02d%02d", now.month, now.day, now.hour, now.minute)
  dir = "../scoreboard/#{datetime}"
  if !Dir.exists?(dir)
    Dir.mkdir(dir)
  end
  api = API.new

  res = api.send("S" + StringT.convert("get scoreboard")).eval(Ctx.new).to_s
  global = Scoreboard.parse(res, "global")
  global.output("#{dir}/global.html", "global")

  global.categories.each do |cat|
    res = api.send("S" + StringT.convert("get scoreboard #{cat}")).eval(Ctx.new).to_s
    rank = Scoreboard.parse(res, cat)
    rank.output("#{dir}/#{cat}.html", cat)
  end
end

main
