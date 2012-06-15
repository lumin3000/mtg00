#some helper
Array.prototype.shuffle = ->
  s = []
  s.push @splice(Math.random() * @length, 1)[0] while @length
  @push s.pop() while s.length
  this


Meteor.startup ->
  if Site.find({}).count() is 0
    Site.insert
      name:'site'
      user: 0
      battle: 0


battleZones = ['Hand','Stack','Graveyard','Exile','Battlefield','Reveals','Library','Examine']
battleMethods = 
  tap:(r)->
    r.d if r.d[r.p].battlefield[r.index].tap = true
  untap:(r)->
    r.d unless r.d[r.p].battlefield[r.index].tap = false
  plus:(r)->
    ++r.d[r.p].battlefield[r.index].counters
    r.d
  minus:(r)->
    --r.d[r.p].battlefield[r.index].counters
    r.d
  tokenDestory:(r)->
    r.d if r.d[r.p].battlefield.splice r.index,1
  txt:(r)->
    r.d[r.p].battlefield[r.index].txt=r.count
    r.d


Meteor.methods
  battleMethods:->
    methods = []
    (methods.push "#{source.toLowerCase()}To#{target}" if source!=target) for target in battleZones for source in battleZones
    ['tap','untap','plus','minus','tokenDestory','txt'].concat methods
(->
  
  store = (r,st)->
    if st=='stack' || st=='reveals'
      r.d[st]
    else
      r.d[r.p][st]
  storeFx = (r,t)->
    if t=='stack' || t=='reveals'
      r.d[t] = [].concat r.d[r.p][t]
      delete r.d[r.p][t]
    r.d
  lowerCase = (str,fn)->fn str.toLowerCase()
  for preSource in battleZones
    ((source)->
      for preTarget in battleZones
        methodName = "#{source}To#{preTarget}"
        if preTarget == "Library"
          battleMethods[methodName] = lowerCase preTarget,(target)->
            (r)->
              if r.count
                r.d[r.p][target] = store(r,source).splice(r.index,r.count||1).concat store r,target
                message.update (message:"将#{r.count||1}张牌放入了牌库顶",type:'inverse'),r.d.log,r.d[r.p].user
              else
                r.d[r.p][target] = store(r,target).concat store(r,source).splice r.index,r.count||1
                message.update (message:"将#{r.count||1}张牌放入了牌库底",type:'inverse'),r.d.log,r.d[r.p].user
              storeFx r,target
        else if preTarget == "Battlefield"
          battleMethods[methodName] = lowerCase preTarget,(target)->
            (r)->storeFx r,target if r.d[r.p][target] = [image:store(r,source).splice(r.index,r.count||1)[0],counters:0].concat store r,target
        else if source == 'battlefield'
          battleMethods[methodName] = lowerCase preTarget,(target)->
            (r)->
              res = store(r,source).splice r.index,r.count||1
              res[i] = res[i].image for i in [0..res.length-1]
              r.d[r.p][target] = res.concat store r,target
              storeFx r,target       
        else
          battleMethods[methodName] = lowerCase preTarget,(target)->
            (r)->storeFx r,target if r.d[r.p][target] = store(r,source).splice(r.index,r.count||1).concat store r,target
    ) preSource.toLowerCase()
)()


Battle = 
  show:(battleId,pos,index,count)->
    d  = Battles.findOne _id:battleId
    if pos
      d:d,p:pos,index:index,count:count || null
    else
      d
  update:(d)->
    Battles.update _id:d._id,d
  getOpponent:(player)->
    if player =='south' then 'north' else 'south'
    
(->    
  for key of battleMethods
    battleMethods[key] = _.compose Battle.update,battleMethods[key],Battle.show
)()


Meteor.methods battleMethods

battleMethods2=
  turnBegin:(battleId,player)->
    d = Battle.show battleId
    d[Battle.getOpponent player].turn = false
    d[player].turn = true
    Battle.update d
  turnFin:(battleId,player)->
    d = Battle.show battleId  
    d[Battle.getOpponent player].turn = true
    d[player].turn = false
    Battle.update d
  lifePlus:(battleId,player)->
    d = Battle.show battleId  
    d[player].life++
    Battle.update d   
  lifeMinus:(battleId,player)->
    d = Battle.show battleId  
    d[player].life--
    Battle.update d
  poisonPlus:(battleId,player)->
    d = Battle.show battleId  
    d[player].poison++
    Battle.update d   
  poisonMinus:(battleId,player)->
    d = Battle.show battleId  
    d[player].poison--
    Battle.update d     
  shuffle:(battleId,player)->
    d = Battle.show battleId
    d[player].library.shuffle()
    tempArray = [[],[],[],[],[],[],[],[]]
    tempArray[i%(tempArray.length-1)].push d[player].library[i] for i in [0..d[player].library.length-1]
    d[player].library = []
    d[player].library = d[player].library.concat tempArray[i] for i in [0..tempArray.length-1]
    Battle.update d
  attach:(battleId,player,sourceIndex,targetIndex,land)->
    d = Battle.show battleId
    d[player].battlefield[sourceIndex].land = true if land
    delete d[player].battlefield[sourceIndex].land if targetIndex==0
    d[player].battlefield[sourceIndex].attaching = if targetIndex==0 then false else true
    d[player].battlefield.splice targetIndex,0,d[player].battlefield.splice(sourceIndex,1)[0]
    Battle.update d
  tokenCreate:(battleId,player)->
    d = Battle.show battleId  
    d[player].battlefield = [image:'transparent.png',counters:1,token:true].concat d[player].battlefield
    Battle.update d
  fightFin:(battleId,player,nullPlayer)->
    d = Battle.show battleId  
    for key,value of nullPlayer
      d[player][key]=value if key!='user'
    d.stack=d.reveals=[]
    Battle.update d

Meteor.methods battleMethods2






