= Restr

<b>Restr is a very simple client for RESTful[http://en.wikipedia.org/wiki/Representational_State_Transfer] 
web services.</b> It is developed as a lightweight alternative to 
ActiveResource[http://api.rubyonrails.com/files/vendor/rails/activeresource/README.html]. 

For project info and downloads please see http://rubyforge.org/projects/restr


*Author*::    Matt Zukowski (matt at roughest dot net)
					Philippe Monnet (techarch@monnet-usa.com)
*Copyright*:: Copyright (c) 2008 Urbacon Ltd.
*License*::   GNU Lesser General Public License Version 3



Restr is basically a wrapper around Ruby's Net::HTTP, offering
a more RESTfully meaningful interface.

See the Restr class documentation for more info, but here's a simple
example of RESTful interaction with Restr:

  require 'restr'
  kitten = Restr.get('http://example.com/kittens/1.xml')
  puts kitten['name']
  puts kitten['colour']
  
  kitten['colour'] = 'black'
  kitten = Restr.put('http://example.com/kittens/1.xml', kitten)


== License

Restr is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published 
by the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Restr is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.