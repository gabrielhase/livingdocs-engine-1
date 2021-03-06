compose = require('../../../src/modules/compose')

class Indestructible

  constructor: -> @everlasting = true
  isInvincible: -> true


class Flying

  constructor: -> @speed = 0
  fly: -> @speed = 1000


describe "(modules) compose:", ->

  describe 'compose a Hero class', ->
    beforeEach ->
      @Hero = compose(Indestructible, Flying)


    it "returns a function with a prototype", ->
      expect(@Hero).to.be.an.instanceof(Function)
      expect( @Hero::fly ).to.exist
      expect( @Hero::isInvincible ).to.exist


    it "returns a function with a prototype", ->
      hero = new @Hero()
      expect(hero.speed).to.equal(0)
      expect(hero.everlasting).to.equal(true)


    it "works as expected", ->
      hero = new @Hero()
      hero.fly()
      expect(hero.speed).to.equal(1000)

