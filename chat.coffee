# Initialize Messages from MongoDB "messages" collection
Messages   = new Meteor.Collection "messages"
Decks      = new Meteor.Collection "decks"
Battles    = new Meteor.Collection "battles"
BattleLogs = new Meteor.Collection "battlelogs"
BattleDecks= new Meteor.Collection "battledecks"
Site       = new Meteor.Collection "site"



message = (->
  messagesId:false
  create:(d,u)->
    Messages.insert messages:[user:u||user.show(),message:d.message,type:d.type]
  update:(d,id,u)->
    d = message:d,type:'normal' if typeof d == 'string'
    messages = @index @messagesId||id
    messages = messages.splice(messages.length-101) if message.length-200>0
    messages.push user:u||user.show(),message:d.message,type:d.type
    Messages.update (_id:@messagesId||id),messages:messages
  index:(id)->
    Messages.findOne(_id:id).messages
)() 

if Meteor.is_client

#some helper
  Array.prototype.shuffle = ->
    s = []
    s.push @splice(Math.random() * @length, 1)[0] while @length
    @push s.pop() while s.length
    this


  Handlebars.registerHelper 'each_with_index', (array, fn) ->
    buffer = ''
    for i in array
      hash = {}
      hash.item = i
      hash.index = _i
      buffer += fn hash
    buffer
    
  stringHelper = 
    links:(links)->
      linkHtml=(klass,text,name,rel)->"<a href=# class=#{klass} name=\"#{name ||''}\" rel=\"#{rel || ''}\">#{text}</a>"
      (->linkHtml l[0],l[1],l[2]||null,l[3]||null for l in links)().join ''
    cardHash:(imageUrl)->
      imageUrl.replace('.jpg','').replace Card._domain,''
      
      
  closeModal = ->
    for d in $ ".modal"
      dom = $ d 
      dom.modal 'hide' if dom.hasClass 'in'
    true

    


  stopEvent = (e)->
    e.stopPropagation()
    e.preventDefault()


  initCards = ()->
    window.Card = _domain:'http://117.79.233.23:3789/'
    cards    = window.cardlib.split ','
    for i in [0..cards.length-1]
      cardInfo  = cards[i].split '/'
      pack      = cardInfo[0]
      dir       = cardInfo[1]
      url       = cardInfo[2]
      Card[pack]={} if !Card[pack]
      Card[pack][dir]=[] if !Card[pack][dir]
      Card[pack][dir].push "#{Card._domain}#{cards[i]}"
  
  nullJsonStr = JSON.stringify {}
  Session.set 'dirs', nullJsonStr
  Session.set 'dir', nullJsonStr
  Session.set 'dirImages', nullJsonStr
  
  initDir = ->
    Session.set 'dirs',JSON.stringify window.carddir  
  
  page = (->
    Template.pages.pages = ->
      Session.get 'pages'
    
    Template.pages.events =
      'click #dirtohome':->
        Session.set 'pages','portal'       
  )()
  
  confirm=(word,fn)->
    dom = $ '#modalConfirm'
    $('#theWordsToBeComfirm').html word
    $('#modalConfirm .btn-primary').off()
    $('#modalConfirm .btn-primary').on "click", ->
      dom.modal 'hide'
      fn()
    dom.modal 'show'
    
  zoomIn=(html)->
    dom = $ '#modalZoomIn'
    $('#theHtmlToBeZoomIn').html html
    dom.modal 'show'
  
  portal = (->
    Template.portal.events =
      'click #gotodeck': ->
        deck.deleteSession()
        user.auth 'deck'
        $('.dirs')[0].click()
        Meteor.setTimeout (->$('.dir')[0].click()),100
      'click #gotoarena': ->
        user.auth 'arenaentry'
  )() 
 

  
  user = (->
    
   Template.register.events =
     'keyup #usernameinput': (event) ->
       user.create() if event.type == "keyup" && event.which == 13# [ENTER]
     'click #usernamebtn' : -> 
       user.create()
    
    auth:(next)->
      if !$.cookie 'username'
        Session.set 'nextpage',next
        Session.set 'pages', 'register'
      else
        Session.set 'pages', next    
    create: ->
      input = $ '#usernameinput'
      return true if !input.val() || input.val().trim()==''
      $.cookie 'username',input.val().trim(),expires:3660
      $('#usernamediv').addClass 'fade'
      Meteor.setTimeout (->Session.set 'pages',Session.get('nextpage') || 'portal'),1000
    show: ->
      $.cookie 'username'
  )()
  
  
  top.site= (->
    
    battle:
      create:(next)->
        Site.update {name:'site'},{$inc:{battle:1}},next
      show:()->
        Site.findOne()
    
  )()
  
  top.battle = (->
    nullPlayer = 
      user:""
      deck:""
      hand:[]
      library:[]
      graveyard:[]
      exile:[]
      battlefield:[]
      examine:[]
      life:20
      poison:0
      turn:false
      fighting:false
      
    nullBattle = 
      south:$.extend {}, nullPlayer
      north:$.extend {}, nullPlayer
      stack:[]
      reveals:[]
      log:""
      
    nullBattleJson = JSON.stringify nullBattle
    battleId = false
    player = false
    opponent = false
    self = false
    
    #Session.set 'battle', nullBattleJson
    

    mask = 
      create:(target,html)->
        dom = $ '#small_image_mask'
        dom.html html
        dom.css top:target.offset().top,display:'block'
        if target.hasClass 'rotate'
          dom.css
            left:target.offset().left
            width:192
            height:132
        else
          dom.css
            left:target.offset().left
            width:132
            height:192            
    index_name = (target)->
      name = target.attr 'name'
      name = 0 if name==''
      parseInt name,10
    count_rel = (target)->
      rel = target.attr 'rel'
      parseInt rel,10 if rel!=''
    
            
    Template.messages.messages = ->
      if message.messagesId
        Meteor.setTimeout (->$("#messages").scrollTop 9999999),150
        message.index message.messagesId
      else
        []
    
    Template.battles.battle = ->
      data = battle.store.get()
      ['south','north'].forEach (el)->
        data[el].handLength = (data[el].hand.length+data[el].examine.length)*204
        data[el].fieldLength = data[el].battlefield.length*204
        data[el].staff  = []
        data[el].land   = []
        for i in data[el].battlefield
          i.html=[]
          i.html.push "#{$('<div/>').text(i.txt).html()}" if typeof i.txt == 'string'
          i.html.push '⬅ 佩带/附着'if i.attaching
          i.html.push if i.counters==0 then '' else "#{i.counters}/#{i.counters}"
          i.html = "#{i.html.join '<br />'}<br /><br />&nbsp;"
          if i.image.indexOf('/land/')>=0
            data[el].land.push index:_i,item:i
          else
            data[el].staff.push index:_i,item:i
      if opponent
        data.othersLength = (data.reveals.length+data.stack.length+data[opponent].battlefield.length)*204
      data
      
    Template.battledeck.battleId = ->
      Session.get 'battleId'
    
    
    Template.battleentry.battleId = ->
      $.cookie('battleId') || ''
    Template.battleentry.events=
      'click #new-battle-btn': ->
        battle.create battle.edit
      'keyup #battle-entry-input': (event) ->
        if event.type == "keyup" && event.which == 13# [ENTER]
          battle.join $("#battle-entry-input").val()
      'click #battle-entry-btn': ->
        battle.join $("#battle-entry-input").val()


    Template.battles.events = 
      'click .zoomIn':(event)->
        imageUrl = $(event.target).attr 'name'
        zoomIn "<img src=\"#{imageUrl}\" />"
        $('#small_image_mask').css 'display','none'
      'keyup #messageInput':(event)->
        dom = $ event.target
        if event.type == "keyup" && event.which == 13 && dom.val()!='' # [ENTER] 
          message.update dom.val()
          dom.val ''
      'click #turnBegin':->
        battle.play 'turnBegin'
        message.update message:'回合开始',type:'inverse'
      'click #turnFin':->
        battle.play 'turnFin'
        message.update message:'回合结束',type:'inverse'
      'click #shuffle':->
        battle.play 'shuffle'
        message.update message:'洗了一次牌',type:'inverse'  
      'click #libToHand':->
        battle.play 'libraryToHand',0,1
        message.update message:'摸了一张牌',type:'inverse' 
      'click #libToExamine':->
        battle.play 'libraryToExamine',0,1
        message.update message:'检视一张牌',type:'inverse'
      'click #preModalLibrary':->
        confirm '查看牌库是一个公开动作,确定要继续么?',->
          $('#modalLibrarySelf').modal 'show'
          message.update message:'查看牌库',type:'inverse' 
      'click #handToReveals':->
        battle.play 'handToReveals',0,1000
        message.update message:'展示手牌',type:'inverse' 
      'click #tokenCreate':->
        battle.play 'tokenCreate'
        message.update message:'创建一个衍生物',type:'inverse' 
      'keyup #txtInput': (event) ->
        if event.type == "keyup" && event.which == 13# [ENTER]
          playHelper.txt $('#txtHidden').val(),$('#txtInput').val()
      'click #txtBtn': ->
        playHelper.txt $('#txtHidden').val(),$('#txtInput').val()
      'click #lifePlus':->battle.play 'lifePlus',0,->message.update message:'生命+1',type:'inverse'
      'click #lifeMinus':->battle.play 'lifeMinus',0,->message.update message:'生命-1',type:'inverse'
      'click #poisonPlus':->battle.play 'poisonPlus',0,->message.update message:'中毒+1',type:'inverse'
      'click #poisonMinus':->battle.play 'poisonMinus',0,->message.update message:'中毒-1',type:'inverse'
      'click #libHand7':->
        confirm '是否确认要摸七张牌?',->
          battle.play 'libraryToHand',0,7
          message.update message:'摸了七张牌',type:'inverse'
      'click #fightFin':->
        confirm '<span class="alert alert-error">是否确认要放弃比赛? 此动作不可撤销哟</span>', ->
          battle.play 'fightFin',nullPlayer,->
            message.update message:'已经放弃比赛了',type:'important'           
            battle.edit()
      'click #msgDice':->
        message.update message:"掷了个骰子: #{parseInt Math.random()*21,10}",type:'inverse'
      'click #msgPreAttack':->
        message.update message:'准备攻击',type:'warning'
      'click #msgPreFin':->
        message.update message:'准备结束回合',type:'warning'
      'click #msgPass':->
        message.update message:'左思右量还是让过好了',type:'success'
      

          

      'click #modalLibrarySelf .dir_images':(e)->
        dom = $ e.target
        index = index_name dom
        mask.create dom,stringHelper.links [
          ['libraryToHand','手牌',index]
          ['libraryToStack','堆叠',index]
          ['libraryToBattlefield','上场',index]
          ['libraryToGraveyard','坟场',index]
          ['libraryToExile','放逐',index]
          ['libraryToReveals','展示',index]
        ]
      'click #modalGraveyardSelf .dir_images':(e)->
        dom = $ e.target
        index = index_name dom
        mask.create dom,stringHelper.links [
          ['graveyardToHand','手牌',index]
          ['graveyardToStack','堆叠',index]
          ['graveyardToBattlefield','上场',index]
          ['graveyardToExile','放逐',index]
          ['graveyardToLibrary','牌库顶',index,1]
          ['graveyardToLibrary','牌库底',index,0]    
        ]
      'click #modalExileSelf .dir_images':(e)->
        dom = $ e.target
        index = index_name dom
        mask.create dom,stringHelper.links [
          ['exileToHand','手牌',index]
          ['exileToStack','堆叠',index]
          ['exileToBattlefield','上场',index]
          ['exileToGraveyard','坟场',index]
          ['exileToLibrary','牌库顶',index,1]
          ['exileToLibrary','牌库底',index,0]    
        ]         
      'click .handcard .dir_images':(e)->
        dom = $ e.target
        index = index_name dom
        mask.create dom,stringHelper.links [
          ['handToStack','堆叠',index]
          ['handToBattlefield','上场',index]
          ['handToGraveyard','坟场',index]
          ['handToExile','放逐',index]
          ['handToReveals','展示',index]
          ['handToLibrary','牌库顶',index,1]
          ['handToLibrary','牌库底',index,0]
          ['zoomIn','放大',dom.attr 'title']
        ]
      'click .self .fieldcard .dir_images':(e)->
        dom = $ e.target
        index = index_name dom
        links = [
          ['tap','横置',index]
          ['untap','重置',index]
          ['plus','+1/+1',index]
          ['minus','-1/-1',index]       
        ]
        if dom.hasClass 'attaching'
          links.push ['changePositionZero','取消佩带',index]
        else
          links = links.concat [['changePositionBegin','佩带附着',index],['changePositionFin','佩上附上',index]]
        if dom.hasClass 'token'
          links = links.concat [['tokenDestory','消失',index]]
        else
          links = links.concat [
            ['battlefieldToHand','手牌',index]
            ['battlefieldToStack','堆叠',index]
            ['battlefieldToGraveyard','坟场',index]
            ['battlefieldToExile','放逐',index]
            ['battlefieldToLibrary','牌库顶',index,1]
            ['battlefieldToLibrary','牌库底',index,0]    
          ]
        links = links.concat [
          ['txtModal','标注',index]
          ['zoomIn','放大',dom.attr 'title']
        ]
        mask.create dom,stringHelper.links links
      'click .stackcard .dir_images':(e)->
        dom = $ e.target
        index = index_name dom
        mask.create dom,stringHelper.links [
          ['stackToHand','手牌',index]
          ['stackToBattlefield','上场',index]
          ['stackToGraveyard','坟场',index]
          ['stackToExile','放逐',index]
          ['stackToLibrary','牌库顶',index,1]
          ['stackToLibrary','牌库底',index,0]
          ['zoomIn','放大',dom.attr 'title']
        ]
      'click .examinecard .dir_images':(e)->
        dom = $ e.target
        index = index_name dom
        mask.create dom,stringHelper.links [
          ['examineToHand','手牌',index]
          ['examineToReveals','展示',index]
          ['examineToStack','堆叠',index]
          ['examineToBattlefield','上场',index]
          ['examineToGraveyard','坟场',index]
          ['examineToExile','放逐',index]
          ['examineToLibrary','牌库顶',index,1]
          ['examineToLibrary','牌库底',index,0]
          ['zoomIn','放大',dom.attr 'title']
        ]

      'click .revealscard .dir_images':(e)->      
        dom = $ e.target
        index = index_name dom
        mask.create dom,stringHelper.links [
          ['revealsToHand','手牌',index]
          ['revealsToStack','堆叠',index]
          ['revealsToBattlefield','上场',index]
          ['revealsToGraveyard','坟场',index]
          ['revealsToExile','放逐',index]
          ['revealsToLibrary','牌库顶',index,1]
          ['revealsToLibrary','牌库底',index,0]
          ['zoomIn','放大',dom.attr 'title']
        ]
      
      'click .opponent .fieldcard .dir_images':(e)->
        dom = $ e.target
        index = index_name dom
        mask.create dom,stringHelper.links [['zoomIn','放大',stringHelper.backgroundImage dom]]      

      'click #small_image_mask':(e)->
        dom = $ e.target
        dom.css 'display','none'
        dom.empty()
    
    playHelper = (->
      changePositionCache=false
      changePositionBegin:(sourceIndex)->
        $("#small_image_mask").css 'display','none'
        changePositionCache = sourceIndex
      changePositionFin:(targetIndex)->
        return true if changePositionCache==false
        targetIndex = if targetIndex==true then 0 else targetIndex+1
        Meteor.call "attach",battleId,player,changePositionCache,targetIndex
        changePositionCache = false
      changePositionZero:(sourceIndex)->
        @changePositionBegin sourceIndex
        @changePositionFin true
      txtModal:(index)->
        $('#modalTxt').modal 'show'
        $('#txtHidden').val "#{index}"
      txt:(index,str)->
        index = parseInt index,10
        $('#modalTxt').modal 'hide'
        Meteor.call 'txt',battleId,player,index,str
    )() 
 
    Meteor.call "battleMethods",(error,methods)->
      methods.push key for key of playHelper
      ((eventName)->
        Template.battles.events["click .#{eventName}"] = (e)->
          stopEvent e
          target = $ e.target 
          closeModal()
          console.log "eventName:#{eventName}"
          battle.play eventName,index_name(target),count_rel target
      ) eventName for eventName in methods
    
    getPlayer = (data)-> #should return south || north || undefined
      for el in ['south','north']
        return el if data[el].user==user.show()
    newPlayer = (data)-> #should return south || north || undefined
      for el in ['south','north']
        return el if data[el].user==''
    saveBattleId = (id)->
      Session.set 'battleId',id
      $.cookie 'battleId',id,expires:30 

        
    play:(fn,index,count)->
      console.log fn+';'+index+";"+count
      return playHelper[fn] index,count||0 if playHelper[fn]
      Meteor.call fn,battleId, player,(if typeof(index)=='undefined' then false else index),count||0

    library:
      create:(deckData)->
        lib = []
        for key, value of deckData
          for i in [0..value-1]
            lib.push "#{Card._domain}#{key}.jpg"
        lib
    store:
      set: (data,next)->
        ['self','opponent'].forEach (el)->delete data[el]
        console.log 'set:'
        console.log data
        Battles.update _id:battleId,data,->
          #Session.set 'battle',JSON.stringify data
          next() if next
      get: ->
        data = Battles.findOne(_id:battleId) || $.extend {},nullBattle
        #data = JSON.parse Session.get 'battle'
        data.self = data[player] || data.south
        data.self.pos = player
        data.opponent = data[opponent] || data.north
        data.opponent.pos = opponent
        console.log 'get:'
        console.log data
        data
      find: (bid)->
        data = Battles.findOne battleId:parseInt bid,10
        if data then data._id else false    
    #player:player
    #opponent:opponent
    create: (next)->
      data = $.extend {},nullBattle
      site.battle.create ->
        data.south.user = user.show()
        data.battleId = site.battle.show().battle
        battleId = Battles.insert data
        saveBattleId data.battleId
        #Session.set 'battle',JSON.stringify data
        next()
    join:(bid)-> 
      battleId = @store.find bid
      return false if battleId == false
      data = @store.get()
      player = getPlayer data
      if player == 'north' || player=='south'
        return @show() if data[player].fighting
      if typeof player == 'undefined'
        player = newPlayer data
      return false if typeof player == 'undefined'
      data[player].user = user.show()
      @store.set data, =>
        saveBattleId data.battleId
        @edit()
    edit:->
      Session.set 'pages','arenadeck'
      deck.deleteSession()
    show: ()->
      saveMessagesId = (id)->message.messagesId = id
      data = @store.get()
      player = getPlayer data
      opponent = if player =='south' then 'north' else 'south'
      saveBattleId data.battleId
      if data[player].fighting
        saveMessagesId data.log
        return Session.set 'pages','arena' 
      else
        myDeck = deck.store.get()
        return true if !myDeck._id
        delete myDeck._id
        welcomeMsg = message:'加入比赛',type:'info'
        if data.log==''
          data.log = message.create welcomeMsg
          saveMessagesId data.log
        else
          saveMessagesId data.log
          message.update welcomeMsg 
        saveMessagesId data.log
        data[player].deck = BattleDecks.insert myDeck
        data[player].library = @library.create myDeck.deck1 
        data[player].fighting = true
      @store.set data,->Session.set 'pages','arena'

    init:->
      self = this
  )()
  
  
  
  top.deck= (->
    nullDeck = "deck1-total":0,"deck2-total":0,deck1:{},deck2:{}
    nullDeckJson = JSON.stringify nullDeck
    Session.set 'deck',nullDeckJson
       
    online = false
    deckId = false 
    
    mask = (->
      getParent:(target)->
        parent = ["#decklist","#battle-deck"]
        for el in parent
          return el if target.parents(el).length>0
      create:(target,html)->       
        dom = $ "#{@getParent(target)} .small_deck_mask"
        dom.html html
        dom.css 
          top:target.position().top
          left:target.position().left
          display:'block'
      destory:(target)->
        dom = $ "#{@getParent(target)} .small_deck_mask"
        dom.css 'display','none'
      name :(e)->
        stopEvent e
        dom = $ e.target
        @destory dom
        dom.attr 'name'
    )()
          
    Template.decks.decks = ->
      Decks.find {},sort:name:1

      
    Template.deck.deckname = ->
      deckSession = deck.store.get()
      deckSession.name || false
    Template.deck.dirImages1 = ->
      deck.view 1
    Template.deck.dirImages2 = ->
      deck.view 2
    Template.deck.cardJson = ->
      deck.view 0

    Template.dirs.deckname = ->
      deckSession = deck.store.get()
      if !deckSession.name
        deckId = false
        '我的套牌'
      else
        deckSession.name      
    Template.dirs.dirs = ->
      JSON.parse Session.get 'dirs'
    
    
    Template.dir.dir = ->
      JSON.parse Session.get 'dir'
    
    Template.dir.dirName = ->
      Session.get 'dirsClicked'
    
    Template.dirImages.dirImages = ->
      JSON.parse Session.get 'dirImages'
    
    Template.dirs.events =
      'click .dirs':(e)->
        dirName = $(e.target).html()
        dir = []
        for key, value of Card[dirName]
          dir.push "#{key}(#{value.length})"
        Session.set 'dir',JSON.stringify dir
        Session.set 'dirsClicked',dirName
      'click #image_mask #add_to_main': (e)->
        stopEvent e
        deck.update 1,Session.get('dirImagesClicked'),'plus'
      'click #image_mask #add_to_backup': (e)->
        stopEvent e
        deck.update 2,Session.get('dirImagesClicked'),'plus'
      'keyup #decknameinput': (event) ->
        if event.type == "keyup" && event.which == 13# [ENTER]
          deck.create $("#decknameinput").val()
          $("#modalNewDeck").modal 'hide'
      'click #decknamebtn':->
        $("#modalNewDeck").modal 'hide'
        deck.create $("#decknameinput").val()      
        
    
    Template.dir.events = 
      'click .dir':(e)->
        dirName = $(e.target).html().split('(')[0]
        Session.set 'dirClicked',dirName
        Session.set 'dirImages',JSON.stringify Card[Session.get('dirsClicked')][dirName]
        $('#image_mask').css 'display','none'
    Template.dirImages.events=
      'click .dir_images':(e)->
        dom = $ e.target
        maskLarge = $ '#image_mask'
        maskLarge.css 'top',dom.position().top
        maskLarge.css 'left',dom.position().left
        maskLarge.css 'display','block'
        Session.set 'dirImagesClicked',stringHelper.cardHash dom.html()
    Template.decks.events = 
      'mouseover .deck-multi-select': (e)->
        if e.target.options
          e.target.size = e.target.options.length
          e.target.style.height ='auto'
      'change .deck-multi-select' : (e)->
        dom = $ e.target
        return true if !dom.val()
        _id = dom.val()[0]
        e.target.options[e.target.options.selectedIndex].selected = ''
        offline = if dom.parent('#battle-decks').length>0 then true else false
        deck.edit Decks.findOne(_id:_id),offline
        #e.target.blur() #this will force ipad error
        

    Template.deck.events=
      'click #resetdeck': ->
        deck.deleteSession()
      'click .battle-begin': ->
        battle.show()
      'click .cardReload':(e)->
        try
          json = JSON.parse $($(e.target).parents('form')[0]).children('textarea').val()
        catch error
          console.log "JSON.parse error: #{error}"
          return false
        deckSession = deck.store.get()
        for el in ['_id','name','user']
          json[el] = deckSession[el] if deckSession[el]
        deck.store.set json
      'click .deck1 .dir_images':(e)->
        dom = $ e.target
        imageUrl = stringHelper.cardHash dom.attr 'name'
        html=[
          "<a href=\"#\" class=\"to2\" name=\"#{imageUrl}\"><i class=\"icon-arrow-down icon-large\" name=\"#{imageUrl}\"></i>备牌</a>"
          "<a href=\"#\" class=\"plus1\" name=\"#{imageUrl}\"><i class=\"icon-plus icon-large\" name=\"#{imageUrl}\"></i>增加</a>"
          "<a href=\"#\" class=\"minus1\" name=\"#{imageUrl}\"><i class=\"icon-minus icon-large\" name=\"#{imageUrl}\"></i>减少</a>"
        ].join ''
        mask.create dom,html
      'click .deck2 .dir_images':(e)->
        dom = $ e.target
        imageUrl = stringHelper.cardHash dom.attr 'name'
        html=[
          "<a href=\"#\" class=\"to1\" name=\"#{imageUrl}\"><i class=\"icon-arrow-up icon-large\" name=\"#{imageUrl}\"></i>主牌</a>"
          "<a href=\"#\" class=\"plus2\" name=\"#{imageUrl}\"><i class=\"icon-plus icon-large\" name=\"#{imageUrl}\"></i>增加</a>"
          "<a href=\"#\" class=\"minus2\" name=\"#{imageUrl}\"><i class=\"icon-minus icon-large\" name=\"#{imageUrl}\"></i>减少</a>"
        ].join ''
        mask.create dom,html
      'click .to2':(e)->
        deck.update 1,mask.name(e),'minus-plus'
      'click .to1':(e)->
        deck.update 2,mask.name(e),'minus-plus'  
      'click .plus1':(e)->
        deck.update 1,mask.name(e),'plus'
      'click .minus1':(e)->
        deck.update 1,mask.name(e),'minus'
      'click .plus2':(e)->
        deck.update 2,mask.name(e),'plus'
      'click .minus2':(e)->
        deck.update 2,mask.name(e),'minus'
      'click #small_deck_mask':(e)->   
        mask.destory $ e.target
        

    
    store:
      set:(data,next)->
        if online
          if !deckId
            deckId = Decks.insert data,next
          else
            Decks.update _id:deckId, data
        Session.set 'deck',JSON.stringify data
      get:->
        JSON.parse Session.get 'deck'
    edit:(data,offline)->
      Session.set 'deck',nullDeckJson
      deckId = data._id
      online = if offline then false else true
      @store.set data
    create:(name)-> #click create button
      return true if name==''
      addOnlineInfo = (data)->$.extend data,name:name,user:user.show()
      #update local cards to new deck after create 
      deckSession = if deckId then addOnlineInfo JSON.parse nullDeckJson else addOnlineInfo @store.get()      
      online = true
      deckId = false
      @store.set deckSession,->
      @init()
    update:(wd,item,operation) -> #click +card button
      deckSession = @show()
      plus = ->
        deckSession["deck#{wd}"] ={} if !deckSession["deck#{wd}"]
        deckSession["deck#{wd}"][item]=0 if !deckSession["deck#{wd}"][item]
        deckSession["deck#{wd}"][item]++
        deckSession["deck#{wd}-total"]++
      minus = ->
        deckSession["deck#{wd}"][item]--
        deckSession["deck#{wd}-total"]--
        delete deckSession["deck#{wd}"][item] if deckSession["deck#{wd}"][item]<=0
        deckSession["deck#{wd}-total"] = 0 if deckSession["deck#{wd}-total"]<=0 
      if operation=='plus'
        plus()
      else if operation=='minus'
        minus()
      else if operation=="minus-plus"
        minus()
        wd = if wd==1 then 2 else 1
        plus()
      @store.set deckSession
    deleteSession: ->
      online = false
      @store.set nullDeck
    delete:(wd,item)->
    show:()->
      @store.get()
    view:(wd)->
      deckSession = @show()
      if wd ==0
        for el in ['_id','name','user']
          delete deckSession[el] if deckSession[el]
        return JSON.stringify deckSession
      ary = total:deckSession["deck#{wd}-total"],list:[]
      for key, value of deckSession["deck#{wd}"]
        ary.list.push key:"#{Card._domain}#{key}.jpg",value:value
      ary.list.reverse()         
      ary
    init: ->
      $('#deck-toggle a:first').tab('show')
  )()

  
  main = ->
    loading = Meteor.setInterval (->
      data = Site.findOne {}
      if data
        site.data = data
        Meteor.clearInterval loading
        Session.set 'loading',0
      ),2000
      

    
    pages = 
      portal: ->
        Session.set 'pages','portal'
      deck: ->
        initCards()
        initDir()
      battle: ->
        battle.init()
        
    value() for key , value of pages
    
    
  Session.set 'loading', 1
  Template.portal.loading = ->
    if Session.equals 'loading',0 then 'loaded' else 'ing'    
  deck.init()
  
  Meteor.startup ->main()




