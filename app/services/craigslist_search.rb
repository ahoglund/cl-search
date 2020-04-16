# frozen_string_literal: true

require 'rss'
require 'uri'

class CraigslistSearch
CITIES = %w[
auburn
bham
dothan
shoals
gadsden
huntsville
mobile
montgomery
tuscaloosa
anchorage
fairbanks
kenai
juneau
prescott
fayar
fortsmith
jonesboro
littlerock
texarkana
bakersfield
chico
fresno
goldcountry
hanford
humboldt
imperial
inlandempire
losangeles
mendocino
merced
modesto
monterey
orangecounty
palmsprings
redding
sacramento
sandiego
sfbay
slo
santabarbara
santamaria
siskiyou
stockton
susanville
ventura
visalia
yubasutter
boulder
cosprings
denver
eastco
fortcollins
rockies
pueblo
westslope
newlondon
hartford
newhaven
nwct
delaware
washingtondc
albanyga
athensga
atlanta
augusta
brunswick
columbusga
macon
nwga
savannah
statesboro
valdosta
honolulu
boise
eastidaho
lewiston
twinfalls
bn
chambana
chicago
decatur
lasalle
mattoon
peoria
rockford
carbondale
springfieldil
quincy
bloomington
evansville
fortwayne
indianapolis
kokomo
tippecanoe
muncie
richmondin
southbend
terrehaute
ames
cedarrapids
desmoines
dubuque
fortdodge
iowacity
masoncity
quadcities
siouxcity
ottumwa
waterloo
lawrence
ksu
nwks
salina
seks
swks
topeka
wichita
bgky
eastky
lexington
louisville
owensboro
westky
batonrouge
cenla
houma
lafayette
lakecharles
monroe
neworleans
shreveport
maine
annapolis
baltimore
easternshore
frederick
smd
westmd
boston
capecod
southcoast
westernmass
worcester
annarbor
battlecreek
centralmich
detroit
flint
grandrapids
holland
jxn
kalamazoo
lansing
monroemi
muskegon
nmi
porthuron
saginaw
swmi
thumb
up
bemidji
brainerd
duluth
mankato
minneapolis
rmn
marshall
stcloud
gulfport
hattiesburg
jackson
meridian
northmiss
natchez
columbiamo
joplin
kansascity
kirksville
loz
semo
springfield
stjoseph
stlouis
billings
bozeman
butte
greatfalls
helena
kalispell
missoula
montana
grandisland
lincoln
northplatte
omaha
scottsbluff
elko
lasvegas
reno
nh
cnj
jerseyshore
newjersey
southjersey
albany
binghamton
buffalo
catskills
chautauqua
elmira
fingerlakes
glensfalls
hudsonvalley
ithaca
longisland
newyork
oneonta
plattsburgh
potsdam
rochester
syracuse
twintiers
utica
watertown
asheville
boone
charlotte
eastnc
fayetteville
greensboro
hickory
onslow
outerbanks
raleigh
wilmington
winstonsalem
bismarck
fargo
grandforks
nd
akroncanton
ashtabula
athensohio
chillicothe
cincinnati
cleveland
columbus
dayton
limaohio
mansfield
sandusky
toledo
tuscarawas
youngstown
zanesville
lawton
enid
oklahomacity
stillwater
tulsa
bend
corvallis
eastoregon
eugene
klamath
medford
oregoncoast
portland
roseburg
salem
altoona
chambersburg
erie
harrisburg
lancaster
allentown
meadville
philadelphia
pittsburgh
poconos
reading
scranton
pennstate
williamsport
york
providence
charleston
columbia
florencesc
greenville
hiltonhead
myrtlebeach
nesd
csd
rapidcity
siouxfalls
sd
chattanooga
clarksville
cookeville
jacksontn
knoxville
memphis
nashville
tricities
logan
ogden
provo
saltlakecity
stgeorge
vermont
charlottesville
danville
fredericksburg
norfolk
harrisonburg
lynchburg
blacksburg
richmond
roanoke
swva
winchester
bellingham
kpr
moseslake
olympic
pullman
seattle
skagit
spokane
wenatchee
yakima
charlestonwv
martinsburg
huntington
morgantown
wheeling
parkersburg
swv
wv
appleton
eauclaire
greenbay
janesville
racine
lacrosse
madison
milwaukee
northernwi
sheboygan
wausau
wyoming
]

ARIZONA_CITIES = %w[
flagstaff mohave phoenix showlow sierravista tucson yuma
]

NEW_MEXICO_CITIES = %w[
albuquerque clovis farmington lascruces roswell santafe
]

FLORIDA_CITIES = %w[
miami
daytona keys fortlauderdale fortmyers gainesville cfl jacksonville lakeland
lakecity ocala okaloosa orlando panamacity pensacola sarasota spacecoast
staugustine tallahassee tampa treasure
]

TEXAS_CITIES = %w[
sanantonio austin waco wichitafalls abilene sanangelo corpuschristi houston
laredo galveston killeen delrio amarillo beaumont brownsville collegestation
dallas nacogdoches elpaso lubbock mcallen odessa sanmarcos bigbend texoma
easttexas victoriatx
]

  ALL              = "ssa"
  ALL_OWNER        = "sso"
  ALL_DEALER       = "ssq"
  CAR_TRUCK_ALL    = "cta"
  CAR_TRUCK_DEALER = "ctd"
  CAR_TRUCK_OWNER  = "ctd"
  GARAGE_MOVING    = "gms"

  class Result
    attr_reader :results, :city

    def initialize(query, city, params = {})
      encoded_query = URI::encode(query)
      @params       = params
      @city         = city
      @url          = url_with_query(encoded_query)
    end

    def results
      require 'open-uri'
      begin
        open(@url) do |rss|
          # feed = RSS::Parser.parse(rss, validate: false)
          SimpleRSS.item_tags << "enc"
          feed = SimpleRSS.parse(rss)
          return {} unless feed

          @results ||= feed.items.each_with_object({}) do |item, obj|
            price = CGI.unescapeHTML(item.title).split(/\$/).last.to_i
            obj[item.link] ||= {}
            obj[item.link][:title] = item.title
            obj[item.link][:price] = price
            obj[item.link][:item] = item
            obj[item.link][:description] = item.description
          end
        end
      rescue SocketError, Net::OpenTimeout
        @results = {}
      end

      @results
    end

    def search_type
      "sss"
    end

    def url_with_query(query)
      "http://#{city}.craigslist.org/search/#{search_type}?#{search_title_only}#{has_pic}format=rss&query=#{query}"
    end

    def search_title_only
      @params[:title_only] ? "srchType=T&" : ""
    end

    def has_pic
      @params[:has_pic] ? "hasPic=1&" : ""
    end
  end

  def search_state(cities)
    cities.each_slice(100) do |slice|
      threads = slice.each_with_object([]) do |city, threads|
        threads << Thread.new do
          @results[city] = Result.new(query, city, params).results
        end
      end

      threads.each(&:join)
    end
  end

  def self.search(query, params)
    new(query, params).tap(&:perform)
  end

  attr_reader :query, :params, :results

  def initialize(query, params)
    @query = query
    @params = params
    @results = {}
  end

  def perform
    search_state(TEXAS_CITIES)
    search_state(NEW_MEXICO_CITIES)
    search_state(FLORIDA_CITIES)
    search_state(ARIZONA_CITIES)
    search_state(CITIES)
  end

end
