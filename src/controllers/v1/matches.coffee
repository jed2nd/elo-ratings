Match = model('v1/match')
User  = model('v1/user')
config = require('../../../config')

MAX_CHALLENGE_GAP = 2

module.exports =
  show: (ctx, res) ->
    id = ctx.params.id
    match = yield Match.findById(id)
    return res.notFound() unless match?
    res.ok(match: match)

  create: (ctx, res) ->
    console.log ctx.body, ctx.body.p1Name
    hasAll = ctx.body.p1Wins? and ctx.body.p2Wins?
    hasAll &&= (ctx.body.p1Id? and ctx.body.p2Id?) or (ctx.body.p1Name? and ctx.body.p2Name?)
    return res.invalid() unless hasAll

    data = yield calculateMatchData(ctx.body)

    p1Saved = yield User.update(data.p1)
    p2Saved = yield User.update(data.p2)

    id = yield Match.create(ctx, data)
    res.ok(id: id)

  list: (ctx, res) ->
    if ctx.req.query?.rebuild
      matches = yield Match.listAll()
      users = yield User.listAll()
      for u, i in users
        u.rating = 2000
        u.matches = 0
        u.wins = 0
        u.ladderPos = i + 1
        yield User.update(u)

      matches = matches.sort((a,b) -> a.createdAt - b.createdAt)
      for m in matches
        body = {}
        body.p1Id = m.p1Id.toString()
        body.p2Id = m.p2Id.toString()

        body.p1Wins = m.p1Wins
        body.p2Wins = m.p2Wins

        body.type   = m.type

        data = yield calculateMatchData(body)

        yield Match.update(m)

        yield User.update(data.p1)
        yield User.update(data.p2)

      res.ok("done")

    else
      res.ok("okay")


calculateMatchData = (body) ->
  if body.p1Id? and body.p2Id?
    p1 = yield User.findById(body.p1Id)
    p2 = yield User.findById(body.p2Id)
  else if body.p1Name? and body.p2Name?
    p1 = yield User.findOrCreateByName(body.p1Name)
    p2 = yield User.findOrCreateByName(body.p2Name)

  data = {}
  data.p1Id = p1._id
  data.p2Id = p2._id
  data.p1Wins = body.p1Wins
  data.p2Wins = body.p2Wins
  data.type   = body.type

  # Calculate ratings:

  data.p1RatingBefore = p1.rating
  data.p2RatingBefore = p2.rating

  if !body.type? || body.type in [ 'rated', 'ladder' ]

    p1RatingAdv = p1.rating - p2.rating
    p2RatingAdv = p2.rating - p1.rating

    p1WinExp = 1 / (Math.pow(10, ((0-p1RatingAdv) / 400)) + 1)
    p2WinExp = 1 / (Math.pow(10, ((0-p2RatingAdv) / 400)) + 1)

    thisK = config.kVal
    winDiff = Math.abs(body.p1Wins - body.p2Wins)
    if winDiff == 2
      thisK *= 1.25
    else if winDiff == 3
      thisK *= 1.5
    else if winDiff > 3
      frac = 0.5 + (winDiff - 3)/8
      thisK *= (1 + frac)

    p1NewRating = data.p1RatingBefore + (thisK * ((body.p1Wins > body.p2Wins) - p1WinExp))
    p2NewRating = data.p2RatingBefore + (thisK * ((body.p2Wins > body.p1Wins) - p2WinExp))

    p1.rating = p1NewRating
    p2.rating = p2NewRating

  data.p1RatingAfter = p1.rating
  data.p2RatingAfter = p2.rating

  # Calculate Ladder:

  if !body.type? || body.type in [ 'ladder' ]

    if body.p1Wins > body.p2Wins
      p1NewLadderPos = Math.min(p1.ladderPos, p2.ladderPos)
      p2NewLadderPos = Math.max(p1.ladderPos, p2.ladderPos)
    else if body.p2Wins > body.p1Wins
      p2NewLadderPos = Math.min(p1.ladderPos, p2.ladderPos)
      p1NewLadderPos = Math.max(p1.ladderPos, p2.ladderPos)

    if p1NewLadderPos < p1.ladderPos #and (p1.ladderPos - p1NewLadderPos) <= MAX_CHALLENGE_GAP
      yield slide(p1.ladderPos, p1NewLadderPos)
      p1.ladderPos = p1NewLadderPos
      p2.ladderPos = p2.ladderPos+1
    else if p2NewLadderPos < p2.ladderPos #and (p2.ladderPos - p2NewLadderPos) <= MAX_CHALLENGE_GAP
      yield slide(p2.ladderPos, p2NewLadderPos)
      p2.ladderPos = p2NewLadderPos
      p1.ladderPos = p1.ladderPos+1

  # Update match count:

  if !body.type? || body.type in [ 'rated', 'ladder' ]

    p1.matches ||= 0
    p2.matches ||= 0
    p1.matches++
    p2.matches++
    p1.wins += body.p1Wins > body.p2Wins
    p2.wins += body.p2Wins > body.p1Wins

  data.p1 = p1
  data.p2 = p2

  return data

slide = (high, low) ->
  users = yield User.listAll()
  for user in users
    if user.ladderPos >= low && user.ladderPos < high
      user.ladderPos = user.ladderPos+1
      yield User.update(user)
  return
