packagesToTest =
  CSS:
    name: 'language-css'
    file: 'test.css'
  SCSS:
    name: 'language-sass'
    file: 'test.scss'
  Less:
    name: 'language-less'
    file: 'test.less'

describe "CSS property name and value autocompletions", ->
  [editor, provider] = []

  getCompletions = (options={}) ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
      activatedManually: options.activatedManually ? true
    provider.getSuggestions(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-css')

    runs ->
      provider = atom.packages.getActivePackage('autocomplete-css').mainModule.getProvider()

    waitsFor -> Object.keys(provider.properties).length > 0

  Object.keys(packagesToTest).forEach (packageLabel) ->
    describe "#{packageLabel} files", ->
      beforeEach ->
        waitsForPromise -> atom.packages.activatePackage(packagesToTest[packageLabel].name)
        waitsForPromise -> atom.workspace.open(packagesToTest[packageLabel].file)
        runs -> editor = atom.workspace.getActiveTextEditor()

      it "returns class completions when not in a property list", ->
        editor.setText('')
        expect(getCompletions()).toBe null

        editor.setText('.d')
        editor.setCursorBufferPosition([0, 0])
        expect(getCompletions()).toBe null

        editor.setCursorBufferPosition([0, 2])
        completions = getCompletions()
        expect(completions).toHaveLength 2
        for completion in completions
          expect(completion.text.length).toBeGreaterThan 0
          expect(completion.type).toBe 'className'

      it "autocompletes property names without a prefix when activated manually", ->
        editor.setText """
          body {

          }
        """
        editor.setCursorBufferPosition([1, 0])
        completions = getCompletions(activatedManually: true)
        expect(completions).toHaveLength 170
        for completion in completions
          expect(completion.text.length).toBeGreaterThan 0
          expect(completion.type).toBe 'property'

      it "does not autocomplete property names without a prefix when not activated manually", ->
        editor.setText """
          body {

          }
        """
        editor.setCursorBufferPosition([1, 0])
        completions = getCompletions(activatedManually: false)
        expect(completions).toEqual []

      it "autocompletes property names with a prefix", ->
        editor.setText """
          .body {
            -fx-background-
          }
        """
        editor.setCursorBufferPosition([1, 17])
        completions = getCompletions()
        expect(completions[0].text).toBe '-fx-background-color: '
        expect(completions[0].displayText).toBe '-fx-background-color'
        expect(completions[0].type).toBe 'property'
        expect(completions[0].replacementPrefix).toBe '-fx-background-'
        expect(completions[0].description.length).toBeGreaterThan 0
        expect(completions[0].descriptionMoreURL.length).toBeGreaterThan 0
        expect(completions[1].text).toBe '-fx-background-insets: '
        expect(completions[1].displayText).toBe '-fx-background-insets'
        expect(completions[1].type).toBe 'property'
        expect(completions[1].replacementPrefix).toBe '-fx-background-'

        editor.setText """
          .body {
            -FX-Background-i
          }
        """
        editor.setCursorBufferPosition([1, 18])
        completions = getCompletions()
        expect(completions).toHaveLength 2
        expect(completions[0].text).toBe '-fx-background-insets: '
        expect(completions[1].text).toBe '-fx-background-image: '
        expect(completions[1].replacementPrefix).toBe '-FX-Background-i'

        # TODO: Re-enable test after Atom 1.12.0 reaches stable
        # editor.setText """
        #   body {
        #     -FX-Background-i:
        #   }
        # """
        # editor.setCursorBufferPosition([1, 18])
        # completions = getCompletions()
        # expect(completions[0].text).toBe '-fx-background-insets: '
        # expect(completions[1].text).toBe '-fx-background-image: '

        editor.setText """
          .body {
            v
          }
        """
        editor.setCursorBufferPosition([1, 3])
        completions = getCompletions()
        expect(completions[0].text).toBe 'visibility: '
        expect(completions[0].displayText).toBe 'visibility'
        expect(completions[0].replacementPrefix).toBe 'v'

      it "does not autocomplete when at a terminator", ->
        editor.setText """
          body {
            .somemixin();
          }
        """
        editor.setCursorBufferPosition([1, 15])
        completions = getCompletions()
        expect(completions).toBe null

      it "does not autocomplete property names when preceding a {", ->
        editor.setText """
          body,{
          }
        """
        editor.setCursorBufferPosition([0, 5])
        completions = getCompletions()
        expect(completions).toBe null

        editor.setText """
          body,{}
        """
        editor.setCursorBufferPosition([0, 5])
        completions = getCompletions()
        expect(completions).toBe null

        editor.setText """
          body
          {
          }
        """
        editor.setCursorBufferPosition([1, 0])
        completions = getCompletions()
        expect(completions).toBe null

      it "does not autocomplete property names when immediately after a }", ->
        editor.setText """
          body{}
        """
        editor.setCursorBufferPosition([0, 6])
        completions = getCompletions()
        expect(completions).toBe null

        editor.setText """
          body{
          }
        """
        editor.setCursorBufferPosition([1, 1])
        completions = getCompletions()
        expect(completions).toBe null

      it "autocompletes property names when the cursor is up against the punctuation inside the property list", ->
        editor.setText """
          body {
          }
        """
        editor.setCursorBufferPosition([0, 7])
        completions = getCompletions()
        expect(completions[0].displayText).toBe '-fx-font'

        editor.setText """
          body {
          }
        """
        editor.setCursorBufferPosition([1, 0])
        completions = getCompletions()
        expect(completions[0].displayText).toBe '-fx-font'

        editor.setText """
          body { }
        """
        editor.setCursorBufferPosition([0, 7])
        completions = getCompletions()
        expect(completions[0].displayText).toBe '-fx-font'

        editor.setText """
          body { }
        """
        editor.setCursorBufferPosition([0, 7])
        completions = getCompletions()
        expect(completions[0].displayText).toBe '-fx-font'

      it "triggers autocomplete when an property name has been inserted", ->
        spyOn(atom.commands, 'dispatch')
        suggestion = {type: 'property', text: 'whatever'}
        provider.onDidInsertSuggestion({editor, suggestion})

        advanceClock 1
        expect(atom.commands.dispatch).toHaveBeenCalled()

        args = atom.commands.dispatch.mostRecentCall.args
        expect(args[0].tagName.toLowerCase()).toBe 'atom-text-editor'
        expect(args[1]).toBe 'autocomplete-plus:activate'

      it "autocompletes property values without a prefix", ->
        editor.setText """
          body {
            -fx-row-valignment:
          }
        """
        editor.setCursorBufferPosition([1, 21])
        completions = getCompletions()
        expect(completions).toHaveLength 4
        for completion in completions
          expect(completion.text.length).toBeGreaterThan 0

        editor.setText """
          body {
            -fx-row-valignment:

          }
        """
        editor.setCursorBufferPosition([2, 0])
        completions = getCompletions()
        expect(completions).toHaveLength 4
        for completion in completions
          expect(completion.text.length).toBeGreaterThan 0

      it "autocompletes property values with a prefix", ->
        editor.setText """
          body {
            -fx-cursor: s
          }
        """
        editor.setCursorBufferPosition([1, 15])
        completions = getCompletions()
        expect(completions).toHaveLength 3
        expect(completions[0].text).toBe 's-resize;'
        expect(completions[1].text).toBe 'se-resize;'
        expect(completions[2].text).toBe 'sw-resize;'

        editor.setText """
          body {
            -fx-cursor: s
          }
        """
        editor.setCursorBufferPosition([1, 15])
        completions = getCompletions()
        expect(completions).toHaveLength 3
        expect(completions[0].text).toBe 's-resize;'
        expect(completions[1].text).toBe 'se-resize;'
        expect(completions[2].text).toBe 'sw-resize;'

        editor.setText """
          body {
            -fx-cursor:
              s
          }
        """
        editor.setCursorBufferPosition([2, 5])
        completions = getCompletions()
        expect(completions).toHaveLength 3
        expect(completions[0].text).toBe 's-resize;'
        expect(completions[1].text).toBe 'se-resize;'
        expect(completions[2].text).toBe 'sw-resize;'

        editor.setText """
          body {
            -fx-column-halignment:
          }
        """
        editor.setCursorBufferPosition([1, 24])
        completions = getCompletions()
        expect(completions).toHaveLength 3
        expect(completions[0].text).toBe 'center;'
        expect(completions[1].text).toBe 'left;'
        expect(completions[2].text).toBe 'right;'

        editor.setText """
          body {
            -fx-column-halignment: c
          }
        """
        editor.setCursorBufferPosition([1, 34])
        completions = getCompletions()
        expect(completions).toHaveLength 1
        expect(completions[0].text).toBe 'center;'

      it "autocompletes inline property values", ->
        editor.setText ".body { -fx-cursor: }"
        editor.setCursorBufferPosition([0, 20])
        completions = getCompletions()
        expect(completions).toHaveLength 17
        expect(completions[0].text).toBe 'crosshair;'

        editor.setText """
          body {
            display: block; -fx-cursor:
          }
        """
        editor.setCursorBufferPosition([1, 34])
        completions = getCompletions()
        expect(completions).toHaveLength 17
        expect(completions[0].text).toBe 'crosshair;'

      it "autocompletes more than one inline property value", ->
        editor.setText ".body { display: block; visibility: }"
        editor.setCursorBufferPosition([0, 35])
        completions = getCompletions()
        expect(completions).toHaveLength 4
        expect(completions[0].text).toBe 'collapse;'

      it "autocompletes inline property values with a prefix", ->
        editor.setText ".body { -fx-blend-mode: c }"
        editor.setCursorBufferPosition([0, 25])
        completions = getCompletions()
        
        expect(completions).toHaveLength 2
        expect(completions[0].text).toBe 'color-burn;'
        expect(completions[1].text).toBe 'color-dodge;'

        editor.setText ".body { -fx-blend-mode: c}"
        editor.setCursorBufferPosition([0, 25])
        completions = getCompletions()
        expect(completions).toHaveLength 2
        expect(completions[0].text).toBe 'color-burn;'
        expect(completions[1].text).toBe 'color-dodge;'

      it "autocompletes !important in property-value scope", ->
        editor.setText """
          body {
            visibility: visible !im
          }
        """
        editor.setCursorBufferPosition([1, 25])
        completions = getCompletions()

        important = null
        for c in completions
          important = c if c.displayText is '!important'

        expect(important.displayText).toBe '!important'

      it "does not autocomplete !important in property-name scope", ->
        editor.setText """
          body {
            !im
          }
        """
        editor.setCursorBufferPosition([1, 5])
        completions = getCompletions()

        important = null
        for c in completions
          important = c if c.displayText is '!important'

        expect(important).toBe null

      describe "tags", ->
        return # Not supported
        it "autocompletes with a prefix", ->
          editor.setText """
            ca {
            }
          """
          editor.setCursorBufferPosition([0, 2])
          completions = getCompletions()
          expect(completions).toHaveLength 7
          expect(completions[0].text).toBe 'canvas'
          expect(completions[0].type).toBe 'tag'
          expect(completions[0].description).toBe 'Selector for <canvas> elements'
          expect(completions[1].text).toBe 'code'

          editor.setText """
            canvas,ca {
            }
          """
          editor.setCursorBufferPosition([0, 9])
          completions = getCompletions()
          expect(completions).toHaveLength 7
          expect(completions[0].text).toBe 'canvas'

          editor.setText """
            canvas ca {
            }
          """
          editor.setCursorBufferPosition([0, 9])
          completions = getCompletions()
          expect(completions).toHaveLength 7
          expect(completions[0].text).toBe 'canvas'

          editor.setText """
            canvas, ca {
            }
          """
          editor.setCursorBufferPosition([0, 10])
          completions = getCompletions()
          expect(completions).toHaveLength 7
          expect(completions[0].text).toBe 'canvas'

        it "does not autocompletes when prefix is preceded by class or id char", ->
          editor.setText """
            .ca {
            }
          """
          editor.setCursorBufferPosition([0, 3])
          completions = getCompletions()
          expect(completions).toBe null

          editor.setText """
            #ca {
            }
          """
          editor.setCursorBufferPosition([0, 3])
          completions = getCompletions()
          expect(completions).toBe null

      describe "pseudo selectors", ->
        it "autocompletes without a prefix", ->
          editor.setText """
            div: {
            }
          """
          editor.setCursorBufferPosition([0, 4])
          completions = getCompletions()
          expect(completions).toHaveLength 35
          for completion in completions
            text = (completion.text or completion.snippet)
            expect(text.length).toBeGreaterThan 0
            expect(completion.type).toBe 'pseudo-selector'

        # TODO: Enable these tests when we can enable autocomplete and test the
        # entire path.
        xit "autocompletes with a prefix", ->
          editor.setText """
            div:f {
            }
          """
          editor.setCursorBufferPosition([0, 5])
          completions = getCompletions()
          expect(completions).toHaveLength 5
          expect(completions[0].text).toBe ':first'
          expect(completions[0].type).toBe 'pseudo-selector'
          expect(completions[0].description.length).toBeGreaterThan 0
          expect(completions[0].descriptionMoreURL.length).toBeGreaterThan 0

        xit "autocompletes with arguments", ->
          editor.setText """
            div:nth {
            }
          """
          editor.setCursorBufferPosition([0, 7])
          completions = getCompletions()
          expect(completions).toHaveLength 4
          expect(completions[0].snippet).toBe ':nth-child(${1:an+b})'
          expect(completions[0].type).toBe 'pseudo-selector'
          expect(completions[0].description.length).toBeGreaterThan 0
          expect(completions[0].descriptionMoreURL.length).toBeGreaterThan 0

        xit "autocompletes when nothing precedes the colon", ->
          editor.setText """
            :f {
            }
          """
          editor.setCursorBufferPosition([0, 2])
          completions = getCompletions()
          expect(completions).toHaveLength 5
          expect(completions[0].text).toBe ':first'

  Object.keys(packagesToTest).forEach (packageLabel) ->
    if packagesToTest[packageLabel].name in ['language-sass', 'language-less']
      describe "#{packageLabel} files", ->
        beforeEach ->
          waitsForPromise -> atom.packages.activatePackage(packagesToTest[packageLabel].name)
          waitsForPromise -> atom.workspace.open(packagesToTest[packageLabel].file)
          runs -> editor = atom.workspace.getActiveTextEditor()

        it "autocompletes tags and properties when nesting inside the property list", ->
          editor.setText """
            .ca {
              -fx-background-i
            }
          """
          editor.setCursorBufferPosition([1, 18])
          completions = getCompletions()
          expect(completions).toHaveLength 2
          expect(completions[0].text).toBe '-fx-background-insets: '
          expect(completions[1].text).toBe '-fx-background-image: '

        # FIXME: This is an issue with the grammar. It thinks nested
        # pseudo-selectors are meta.property-value.scss/less
        xit "autocompletes pseudo selectors when nested in LESS and SCSS files", ->
          editor.setText """
            .some-class {
              .a:f
            }
          """
          editor.setCursorBufferPosition([1, 6])
          completions = getCompletions()
          expect(completions).toHaveLength 5
          expect(completions[0].text).toBe ':first'

        it "does not show property names when in a class selector", ->
          editor.setText """
            body {
              .a
            }
          """
          editor.setCursorBufferPosition([1, 4])
          completions = getCompletions()
          expect(completions).toBe null

        it "does not show property names when in an id selector", ->
          editor.setText """
            body {
              #a
            }
          """
          editor.setCursorBufferPosition([1, 4])
          completions = getCompletions()
          expect(completions).toBe null

        it "does not show property names when in a parent selector", ->
          editor.setText """
            body {
              &
            }
          """
          editor.setCursorBufferPosition([1, 4])
          completions = getCompletions()
          expect(completions).toBe null

        it "does not show property names when in a parent selector with a prefix", ->
          editor.setText """
            body {
              &a
            }
          """
          editor.setCursorBufferPosition([1, 4])
          completions = getCompletions()
          expect(completions).toBe null

  describe "SASS files", ->
    beforeEach ->
      waitsForPromise -> atom.packages.activatePackage('language-sass')
      waitsForPromise -> atom.workspace.open('test.sass')
      runs -> editor = atom.workspace.getActiveTextEditor()

    it "autocompletes property names with a prefix", ->
      editor.setText """
        body
          -fx-background-
      """
      editor.setCursorBufferPosition([1, 17])
      completions = getCompletions()
      expect(completions).toHaveLength 7
      expect(completions[0].text).toBe '-fx-background-color: '
      expect(completions[0].displayText).toBe '-fx-background-color'
      expect(completions[0].type).toBe 'property'
      expect(completions[0].replacementPrefix).toBe '-fx-background-'
      expect(completions[0].description.length).toBeGreaterThan 0
      expect(completions[0].descriptionMoreURL.length).toBeGreaterThan 0
      expect(completions[1].text).toBe '-fx-background-insets: '
      expect(completions[1].displayText).toBe '-fx-background-insets'
      expect(completions[1].type).toBe 'property'
      expect(completions[1].replacementPrefix).toBe '-fx-background-'

      editor.setText """
        body
          -FX-Background-
      """
      editor.setCursorBufferPosition([1, 17])
      completions = getCompletions()
      expect(completions).toHaveLength 7
      expect(completions[0].text).toBe '-fx-background-color: '
      expect(completions[1].text).toBe '-fx-background-insets: '
      expect(completions[1].replacementPrefix).toBe '-FX-Background-'

      editor.setText """
        body
          -fx-background-:
      """
      editor.setCursorBufferPosition([1, 17])
      completions = getCompletions()
      expect(completions).toHaveLength 7
      expect(completions[0].text).toBe '-fx-background-color: '
      expect(completions[1].text).toBe '-fx-background-insets: '

      editor.setText """
        body
          -fx-background-i
      """
      editor.setCursorBufferPosition([1, 18])
      completions = getCompletions()
      expect(completions[0].text).toBe '-fx-background-insets: '
      expect(completions[0].displayText).toBe '-fx-background-insets'
      expect(completions[0].replacementPrefix).toBe '-fx-background-i'

    it "triggers autocomplete when an property name has been inserted", ->
      spyOn(atom.commands, 'dispatch')
      suggestion = {type: 'property', text: 'whatever'}
      provider.onDidInsertSuggestion({editor, suggestion})

      advanceClock 1
      expect(atom.commands.dispatch).toHaveBeenCalled()

      args = atom.commands.dispatch.mostRecentCall.args
      expect(args[0].tagName.toLowerCase()).toBe 'atom-text-editor'
      expect(args[1]).toBe 'autocomplete-plus:activate'

    it "autocompletes property values without a prefix", ->
      editor.setText """
        body
          -fx-cursor:
      """
      editor.setCursorBufferPosition([1, 13])
      completions = getCompletions()
      expect(completions).toHaveLength 17
      for completion in completions
        expect(completion.text.length).toBeGreaterThan 0

      editor.setText """
        body
          -fx-cursor:
      """
      editor.setCursorBufferPosition([2, 0])
      completions = getCompletions()
      expect(completions).toHaveLength 17
      for completion in completions
        expect(completion.text.length).toBeGreaterThan 0

    it "autocompletes property values with a prefix", ->
      editor.setText """
        body
          -fx-cursor: s
      """
      editor.setCursorBufferPosition([1, 15])
      completions = getCompletions()
      expect(completions).toHaveLength 3
      expect(completions[0].text).toBe 's-resize'
      expect(completions[1].text).toBe 'se-resize'
      expect(completions[2].text).toBe 'sw-resize'

      editor.setText """
        body
          -fx-cursor: S
      """
      editor.setCursorBufferPosition([1, 15])
      completions = getCompletions()
      expect(completions).toHaveLength 3
      expect(completions[0].text).toBe 's-resize'
      expect(completions[1].text).toBe 'se-resize'
      expect(completions[2].text).toBe 'sw-resize'

    it "autocompletes !important in property-value scope", ->
      editor.setText """
        body
          visibility: visible !im
      """
      editor.setCursorBufferPosition([1, 27])
      completions = getCompletions()

      important = null
      for c in completions
        important = c if c.displayText is '!important'

      expect(important.displayText).toBe '!important'

    it "does not autocomplete when indented and prefix is not a char", ->
      editor.setText """
        body
          ~
      """
      editor.setCursorBufferPosition([1, 3])
      completions = getCompletions(activatedManually: false)
      expect(completions).toBe null

      editor.setText """
        body
          #
      """
      editor.setCursorBufferPosition([1, 3])
      completions = getCompletions(activatedManually: false)
      expect(completions).toBe null

      editor.setText """
        body
          .foo,
      """
      editor.setCursorBufferPosition([1, 7])
      completions = getCompletions(activatedManually: false)
      expect(completions).toBe null

      editor.setText """
        body
          foo ~
      """
      editor.setCursorBufferPosition([1, 8])
      completions = getCompletions(activatedManually: false)
      expect(completions).toBe null

      # As spaces at end of line will be removed, we'll test with a char
      # after the space and with the cursor before that char.
      editor.setCursorBufferPosition([1, 7])
      completions = getCompletions(activatedManually: false)
      expect(completions).toBe null

    it 'does not autocomplete when inside a nth-child selector', ->
      editor.setText """
        body
          &:nth-child(4
      """
      editor.setCursorBufferPosition([1, 15])
      completions = getCompletions(activatedManually: false)
      expect(completions).toBe null

    it 'autocompletes a property name with a dash', ->
      editor.setText """
        body
          -fx-border-
      """
      editor.setCursorBufferPosition([1, 13])
      completions = getCompletions(activatedManually: false)
      expect(completions).not.toBe null

      expect(completions[0].text).toBe '-fx-border-color: '
      expect(completions[0].displayText).toBe '-fx-border-color'
      expect(completions[0].replacementPrefix).toBe '-fx-border-'

      expect(completions[1].text).toBe '-fx-border-insets: '
      expect(completions[1].displayText).toBe '-fx-border-insets'
      expect(completions[1].replacementPrefix).toBe '-fx-border-'
          
    it "does not autocomplete !important in property-name scope", ->
      editor.setText """
        body {
          !im
        }
      """
      editor.setCursorBufferPosition([1, 5])
      completions = getCompletions()

      important = null
      for c in completions
        important = c if c.displayText is '!important'

      expect(important).toBe null

    describe "tags", ->
      return # Not supported
      it "autocompletes with a prefix", ->
        editor.setText """
          ca
        """
        editor.setCursorBufferPosition([0, 2])
        completions = getCompletions()
        expect(completions).toHaveLength 7
        expect(completions[0].text).toBe 'canvas'
        expect(completions[0].type).toBe 'tag'
        expect(completions[0].description).toBe 'Selector for <canvas> elements'
        expect(completions[1].text).toBe 'code'

        editor.setText """
          canvas,ca
        """
        editor.setCursorBufferPosition([0, 9])
        completions = getCompletions()
        expect(completions).toHaveLength 7
        expect(completions[0].text).toBe 'canvas'

        editor.setText """
          canvas ca
        """
        editor.setCursorBufferPosition([0, 9])
        completions = getCompletions()
        expect(completions).toHaveLength 7
        expect(completions[0].text).toBe 'canvas'

        editor.setText """
          canvas, ca
        """
        editor.setCursorBufferPosition([0, 10])
        completions = getCompletions()
        expect(completions).toHaveLength 7
        expect(completions[0].text).toBe 'canvas'

      it "does not autocomplete when prefix is preceded by class or id char", ->
        editor.setText """
          .ca
        """
        editor.setCursorBufferPosition([0, 3])
        completions = getCompletions()
        expect(completions).toBe null

        editor.setText """
          #ca
        """
        editor.setCursorBufferPosition([0, 3])
        completions = getCompletions()
        expect(completions).toBe null

    describe "pseudo selectors", ->
      it "autocompletes without a prefix", ->
        editor.setText """
          div:
        """
        editor.setCursorBufferPosition([0, 4])
        completions = getCompletions()
        expect(completions).toHaveLength 35
        for completion in completions
          text = (completion.text or completion.snippet)
          expect(text.length).toBeGreaterThan 0
          expect(completion.type).toBe 'pseudo-selector'
