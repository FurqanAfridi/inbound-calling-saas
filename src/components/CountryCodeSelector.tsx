import React, { useState, useRef, useEffect } from 'react';
import { ChevronDown, Search } from 'lucide-react';
import { countryCodes } from '../data/countryCodes';
import { cn } from '@/lib/utils';
import { Button } from './ui/button';
import { Input } from './ui/input';

interface CountryCodeSelectorProps {
  value: string;
  onChange: (code: string) => void;
}

const CountryCodeSelector: React.FC<CountryCodeSelectorProps> = ({ value, onChange }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const dropdownRef = useRef<HTMLDivElement>(null);

  const selectedCountry = countryCodes.find(c => c.code === value) || countryCodes[0];

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const filteredCountries = countryCodes.filter(
    country =>
      country.country.toLowerCase().includes(searchTerm.toLowerCase()) ||
      country.code.includes(searchTerm)
  );

  return (
    <div className="relative" ref={dropdownRef}>
      <Button
        type="button"
        variant="outline"
        onClick={() => setIsOpen(!isOpen)}
        className="min-w-[120px] justify-between bg-background text-foreground border-border hover:bg-muted"
      >
        <span className="text-lg">{selectedCountry.flag}</span>
        <span className="font-medium">{selectedCountry.code}</span>
        <ChevronDown className={cn("w-4 h-4 transition-transform", isOpen && "rotate-180")} />
      </Button>

      {isOpen && (
        <div className="absolute top-full left-0 right-0 mt-2 bg-card border border-border rounded-lg shadow-lg z-50 max-h-[300px] flex flex-col">
          <div className="p-3 border-b border-border">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                type="text"
                placeholder="Search country..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-9 bg-background text-foreground border-border"
              />
            </div>
          </div>
          <div className="overflow-y-auto max-h-[250px]">
            {filteredCountries.map((country) => (
              <button
                key={country.code}
                type="button"
                onClick={() => {
                  onChange(country.code);
                  setIsOpen(false);
                  setSearchTerm('');
                }}
                className={cn(
                  "w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-muted transition-colors",
                  value === country.code && "bg-primary/10 text-primary"
                )}
              >
                <span className="text-lg">{country.flag}</span>
                <span className="font-medium min-w-[50px]">{country.code}</span>
                <span className="flex-1 text-sm text-muted-foreground">{country.country}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default CountryCodeSelector;
